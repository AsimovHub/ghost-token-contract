// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GhostToken is ERC20 {
    address constant GHOST_TOKEN_ADDRESS = 0xef68A81dccF28EFEEc42043dCD6bbD22701Af4d0;
    uint256 immutable TOKENS_PER_GHOST;

    // SAVE WHICH GHOSTS BELONG TO WHICH USER
    mapping(uint256 => address) internal _tokenOwners;
    mapping(uint256 =>  uint256) internal _lockedDate;

    // SAVE ALL CURRENT LOCKED GHOST OF A USER
    mapping(address => uint256[]) internal _lockedGhosts;

    constructor() ERC20("Ghost Soul", "GSOUL") {
        TOKENS_PER_GHOST = 100000 * 10 ** decimals();


        // TODO: Discuss
        // _mint(msg.sender, TOKENS_PER_GHOST * 10); // Initial value of 10 locked ghosts for DAO wallet
    }

    function getOwnerOfGhost(uint256 tokenId_) external view returns (adress memory) {
        return _tokenOwners[tokenId_];
    }

    function getLockedGhostsOfOwner(address owner_) external view returns (uint256[]) {
        return _lockedGhosts[owner_];
    }

    function withdraw(uint256 tokenId_) external {
        IERC721(GHOST_TOKEN_ADDRESS).transferFrom(address(this), msg.sender, tokenId_);
    }

    function bury(uint256 tokenId_) external {
        require(IERC721(GHOST_TOKEN_ADDRESS).ownerOf(tokenId_) == msg.sender, "You are not owner of this Ghost");
        require(IERC721(GHOST_TOKEN_ADDRESS).getApproved(tokenId_) == address(this), "Ghost has not been approved");

        _tokenOwners[tokenId_] = msg.sender;
        _lockedDate[tokenId_] = block.timestamp;
        _lockedGhosts[msg.sender].push(tokenId_);

        _mint(msg.sender, TOKENS_PER_GHOST);
        IERC721(GHOST_TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), tokenId_);
    }

    function summon(uint256 tokenId_) external {
        require(IERC721(GHOST_TOKEN_ADDRESS).ownerOf(tokenId_) == address(this), "The Ghost is not locked");
        require(_tokenOwners[tokenId_] == msg.sender, "You are not owner of the locked Ghost");
        require(balanceOf(msg.sender) >= TOKENS_PER_GHOST, "You do not hold enough tokens");
        require(allowance(msg.sender, address(this)) > TOKENS_PER_GHOST, "Tokens has not been approved");

        bool removed = false;
        for (uint i = index; i < _lockedGhosts[msg.sender].length; i++){
            if (removed && i < _lockedGhosts[msg.sender].length - 1) {
                _lockedGhosts[msg.sender][i] = _lockedGhosts[msg.sender][i + 1];
            }
            if (_lockedGhosts[msg.sender][i] == tokenId_) {
                delete _lockedGhosts[i];
            }
        }
        if (removed) {
            _lockedGhosts.pop();
        }

        _tokenOwners[tokenId_] = address(0);
        _lockedDate[tokenId_] = 0;
        burnFrom(msg.sender, TOKENS_PER_GHOST);
        IERC721(GHOST_TOKEN_ADDRESS).transferFrom(address(this), _tokenOwners[tokenId_], tokenId_);
    }

    function summonFor(uint256 tokenId_) external {
        require(IERC721(GHOST_TOKEN_ADDRESS).ownerOf(tokenId_) == address(this), "The Ghost is not locked");
        require(balanceOf(msg.sender) >= TOKENS_PER_GHOST, "You do not hold enough tokens");
        require(allowance(msg.sender, address(this)) > TOKENS_PER_GHOST, "Tokens has not been approved");

        address owner_ = _tokenOwners[tokenId_];

        bool removed = false;
        for (uint i = index; i < _lockedGhosts[owner_].length; i++){
            if (removed && i < _lockedGhosts[owner_].length - 1) {
                _lockedGhosts[owner_][i] = _lockedGhosts[owner_][i + 1];
            }
            if (_lockedGhosts[owner_][i] == tokenId_) {
                delete _lockedGhosts[i];
            }
        }
        if (removed) {
            _lockedGhosts.pop();
        }

        _tokenOwners[tokenId_] = address(0);
        burnFrom(msg.sender, TOKENS_PER_GHOST);
        IERC721(GHOST_TOKEN_ADDRESS).transferFrom(address(this), _tokenOwners[tokenId_], tokenId_);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}