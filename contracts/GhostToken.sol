// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract GhostToken is ERC20, IERC721Receiver {
    address constant GHOST_NFT_ADDRESS = 0xef68A81dccF28EFEEc42043dCD6bbD22701Af4d0;
    uint256 constant BLOCKS_PER_YEAR = 10512000;

    uint256 immutable MAXIMUM_TOKEN_REWARD;
    uint256 immutable MINIMUM_TOKEN_REWARD;

    // SAVE WHICH GHOSTS BELONG TO WHICH USER
    mapping(uint256 => address) internal _tokenOwners;
    mapping(uint256 =>  uint256) internal _lockedDate;

    // SAVE ALL CURRENT LOCKED GHOST OF A USER
    mapping(address => uint256[]) internal _lockedGhosts;

    uint256 _mintingStart;

    constructor() ERC20("Ghost Soul", "GSOUL") {
        MAXIMUM_TOKEN_REWARD = 100000 * 10 ** decimals();
        MINIMUM_TOKEN_REWARD = 10000 * 10 ** decimals();

        _mintingStart = block.number;
    }

    function getOwnerOfGhost(uint256 tokenId_) external view returns (address) {
        return _tokenOwners[tokenId_];
    }

    function getLockedGhostsOfOwner(address owner_) external view returns (uint256[] memory) {
        return _lockedGhosts[owner_];
    }

    function getLockDate(uint256 tokenId_) public view returns (uint256) {
        return _lockedDate[tokenId_];
    }

    function getMintingStart() public view returns (uint256) {
        return _mintingStart;
    }

    function getMintingBlockTime() public view returns (uint256) {
        return block.number - getMintingStart();
    }

    function getRewardForYear(uint year_) public view returns (uint256) {
        if (year_ < 12) {
            return (13 - year_)  * 1000 * 10 ** decimals();
        } else {
            return 2 * 1000 * 10 ** decimals();
        }
    }

    function getRewardsDistributedAfterYears(uint year_) public view returns (uint256) {
        if (year_ == 0) {
            return 0;
        }
        return getRewardsDistributedAfterYears(year_ - 1) + getRewardForYear(year_ - 1);
    }

    function getAmount(uint blocktime) public view returns (uint256) {
        uint256 xYear = blocktime / BLOCKS_PER_YEAR;
        uint256 currentYearBlocktime = blocktime % BLOCKS_PER_YEAR;
        uint256 rewardForYear = getRewardForYear(xYear);
        uint256 rewardPerBlocks = (rewardForYear / BLOCKS_PER_YEAR);

        uint256 alreadyDistributedRewards = getRewardsDistributedAfterYears(xYear);
        uint256 reward = MAXIMUM_TOKEN_REWARD - alreadyDistributedRewards - (rewardPerBlocks * currentYearBlocktime);
        if (reward > MINIMUM_TOKEN_REWARD) {
            return reward;
        } else {
            return MINIMUM_TOKEN_REWARD;
        }
    }

    function determineCurrentTokensPerGhost() public view returns (uint256) {
        return getAmount(getMintingBlockTime());
    }

    function bury(uint256 tokenId_) external {
        require(IERC721(GHOST_NFT_ADDRESS).ownerOf(tokenId_) == msg.sender, "You are not owner of this Ghost");
        require(IERC721(GHOST_NFT_ADDRESS).getApproved(tokenId_) == address(this), "Ghost has not been approved");

        _tokenOwners[tokenId_] = msg.sender;
        _lockedDate[tokenId_] = block.timestamp;
        _lockedGhosts[msg.sender].push(tokenId_);

        _mint(msg.sender, determineCurrentTokensPerGhost());
        IERC721(GHOST_NFT_ADDRESS).safeTransferFrom(msg.sender, address(this), tokenId_);
    }

    function summon(uint256 tokenId_) external {
        _summon(msg.sender, msg.sender, tokenId_);
    }

    function summonFor(uint256 tokenId_) external {
        address owner_ = _tokenOwners[tokenId_];
        _summon(msg.sender, owner_, tokenId_);
    }

    function _summon(address payer_, address nftOwner_, uint256 tokenId_) internal {
        require(_tokenOwners[tokenId_] == nftOwner_, "This Ghost does not belong the given address");
        require(IERC721(GHOST_NFT_ADDRESS).ownerOf(tokenId_) == address(this), "The Ghost is not locked");
        uint256 currentTokensPerGhost = determineCurrentTokensPerGhost();
        require(balanceOf(payer_) >= currentTokensPerGhost, "You do not hold enough tokens");
        require(allowance(payer_, address(this)) >= currentTokensPerGhost, "Tokens has not been approved");

        bool removed = false;
        for (uint i = 0; i < _lockedGhosts[nftOwner_].length; i++) {
            if (_lockedGhosts[nftOwner_][i] == tokenId_) {
                removed = true;
            }
            if (removed && i < _lockedGhosts[nftOwner_].length - 1) {
                _lockedGhosts[nftOwner_][i] = _lockedGhosts[nftOwner_][i + 1];
            }
        }
        if (removed) {
            _lockedGhosts[nftOwner_].pop();
        }

        _tokenOwners[tokenId_] = address(0);
        _lockedDate[tokenId_] = 0;
        _spendAllowance(payer_, address(this), currentTokensPerGhost);
        _burn(payer_, currentTokensPerGhost);
        IERC721(GHOST_NFT_ADDRESS).safeTransferFrom(address(this), nftOwner_, tokenId_);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}