// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract GhostToken is ERC20, IERC721Receiver {
    address constant GHOST_NFT_ADDRESS = 0x382E1AB2488C1B9b64C0A331Ea31dAF493561EC9;
    uint256 immutable TOKENS_PER_GHOST;

    // SAVE WHICH GHOSTS BELONG TO WHICH USER
    mapping(uint256 => address) internal _tokenOwners;
    mapping(uint256 =>  uint256) internal _lockedDate;

    // SAVE ALL CURRENT LOCKED GHOST OF A USER
    mapping(address => uint256[]) internal _lockedGhosts;

    constructor() ERC20("Dev Token", "DEV") {
        TOKENS_PER_GHOST = 100000 * 10 ** decimals();


        // TODO: Discuss
        // _mint(msg.sender, TOKENS_PER_GHOST * 10); // Initial value of 10 locked ghosts for DAO wallet
    }

    function getTokensPerGhost() external view returns (uint256) {
        return TOKENS_PER_GHOST;
    }
    function getOwnerOfGhost(uint256 tokenId_) external view returns (address) {
        return _tokenOwners[tokenId_];
    }

    function getLockedGhostsOfOwner(address owner_) external view returns (uint256[] memory) {
        return _lockedGhosts[owner_];
    }

    function withdraw(uint256 tokenId_) external {
        IERC721(GHOST_NFT_ADDRESS).transferFrom(address(this), msg.sender, tokenId_);
    }

    function bury(uint256 tokenId_) external {
        require(IERC721(GHOST_NFT_ADDRESS).ownerOf(tokenId_) == msg.sender, "You are not owner of this Ghost");
        require(IERC721(GHOST_NFT_ADDRESS).getApproved(tokenId_) == address(this), "Ghost has not been approved");

        _tokenOwners[tokenId_] = msg.sender;
        _lockedDate[tokenId_] = block.timestamp;
        _lockedGhosts[msg.sender].push(tokenId_);

        _mint(msg.sender, TOKENS_PER_GHOST);
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
        require(balanceOf(payer_) >= TOKENS_PER_GHOST, "You do not hold enough tokens");
        require(allowance(payer_, address(this)) >= TOKENS_PER_GHOST, "Tokens has not been approved");

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
        _spendAllowance(payer_, address(this), TOKENS_PER_GHOST);
        _burn(payer_, TOKENS_PER_GHOST);
        IERC721(GHOST_NFT_ADDRESS).transferFrom(address(this), nftOwner_, tokenId_);
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