/**
  
     .------..------..------..------.
     |B.--. ||T.--. ||R.--. ||D.--. |
     | :/\: || (\/) || :(): || :/\: |
     | :\/: || :\/: || ()() || (__) |
     | '--'B|| '--'T|| '--'R|| '--'D|
     `------'`------'`------'`------'
                                       _.-="_-         _
                                  _.-="   _-          | ||"""""""---._______     __..
                      ___.===""""-.______-,,,,,,,,,,,,`-''----" """""       """""  __'
               __.--""     __        ,'      TCG          o \    4444   __        [__|  .......+ ++
          __-""=======.--""  ""--.=================================.--""  ""--.=======:  ...........+ +
         ]       [ ] : /        \ : |========================|    : /        \ :  [ ] :   .....+ +
         V___________:|     O    |: |========================|    :|     O    |:   _-"  ....++
          V__________: \        / :_|=======================/_____: \        / :__-"  ...+  +
          -----------'  "-____-"  `-------------------------------'  "-____-"

     ██████╗ ██╗████████╗██╗  ██╗███████╗██╗         ██████╗  ██████╗  █████╗ ██████╗ ███████╗
     ██╔══██╗██║╚══██╔══╝╚██╗██╔╝██╔════╝██║         ██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔════╝
     ██████╔╝██║   ██║    ╚███╔╝ █████╗  ██║         ██████╔╝██║   ██║███████║██║  ██║███████╗
     ██╔══██╗██║   ██║    ██╔██╗ ██╔══╝  ██║         ██╔══██╗██║   ██║██╔══██║██║  ██║╚════██║
     ██████╔╝██║   ██║   ██╔╝ ██╗███████╗███████╗    ██║  ██║╚██████╔╝██║  ██║██████╔╝███████║
     ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract BitxelRoads is ERC721A, ERC2981, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant OG_MAX_SUPPLY = 444;
    uint256 public constant GTD_MAX_SUPPLY = 1000;
    uint256 public constant FCFS_MAX_SUPPLY = 500;

    uint256 private ogMinted;
    uint256 private gtdMinted;
    uint256 private fcfsMinted;
    uint256 private ownerMinted;

    string private baseTokenURI;
    string private placeholderURI;
    bool public revealed = false;
    bool private baseURILocked = false;
    uint256 public offset;
    uint256 public offsetBlock;

    enum MintPhase { Closed, OG, GTD, FCFS, Public }
    MintPhase public currentPhase = MintPhase.Closed;

    uint256 public priceFCFS;
    uint256 public pricePublic;

    // Time tracking for phases
    uint256 public constant PHASE_DURATION = 12 hours;
    mapping(MintPhase => uint256) public phaseStartTime;
    mapping(MintPhase => bool) public phaseEndedByTime;

    mapping(address => bool) private OGList;
    mapping(address => bool) private GTDList;
    mapping(address => bool) private FCFSList;

    mapping(address => uint256) private ogMintedWallets;
    mapping(address => uint256) private gtdMintedWallets;
    mapping(address => uint256) private fcfsMintedWallets;
    mapping(address => uint256) private publicMintedWallets;

    address private treasury;

    event MintExecuted(address indexed minter, uint256 quantity);
    event WithdrawExecuted(address indexed recipient, uint256 amount);
    event MintPhaseChanged(uint256 newPhase);
    event BaseURISet(string newURI);
    event PlaceholderURISet(string newURI);
    event Revealed();
    event OGListAdded(address[] addresses);
    event GTDListAdded(address[] addresses);
    event FCFSListAdded(address[] addresses);
    event TreasuryUpdated(address newTreasury);
    event RoyaltyUpdated(address newReceiver, uint96 newFeeNumerator);
    event PriceFCFSUpdated(uint256 newPrice);
    event PricePublicUpdated(uint256 newPrice);
    event OwnerMintExecuted(address indexed minter, uint256 quantity);

    constructor(
        address _treasury,
        string memory _placeholderURI
    ) ERC721A("Bitxel Road TCG", "BTRD") {
        require(_treasury != address(0), "Treasury address cannot be zero");
        treasury = _treasury;
        placeholderURI = _placeholderURI;
        _setDefaultRoyalty(treasury, 500); // 5% royalties
    }

    modifier whenMintActive() {
        require(currentPhase != MintPhase.Closed, "Minting is not active");
        _;
    }

    function mint(uint256 quantity) external payable nonReentrant whenNotPaused whenMintActive {
        require(quantity > 0, "Quantity must be greater than 0");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");

        // Check if phase has ended by time (except for Public phase)
        if (currentPhase != MintPhase.Public) {
            require(!phaseEndedByTime[currentPhase], "Phase has ended by time limit");
            if (block.timestamp >= phaseStartTime[currentPhase] + PHASE_DURATION) {
                phaseEndedByTime[currentPhase] = true;
                revert("Phase has ended by time limit");
            }
        }

        if (currentPhase == MintPhase.OG) {
            require(OGList[msg.sender], "Not on OG list");
            require(ogMintedWallets[msg.sender] + quantity <= 1, "Max OG mint reached");
            require(msg.value == 0, "OG mint is free");
            require(ogMinted + quantity <= OG_MAX_SUPPLY, "OG supply exhausted");
            ogMintedWallets[msg.sender] += quantity;
            ogMinted += quantity;

        } else if (currentPhase == MintPhase.GTD) {
            require(GTDList[msg.sender], "Not on GTD list");
            require(gtdMintedWallets[msg.sender] + quantity <= 1, "Max GTD mint reached");
            require(msg.value == 0, "GTD mint is free");
            require(gtdMinted + quantity <= GTD_MAX_SUPPLY, "GTD supply exhausted");
            gtdMintedWallets[msg.sender] += quantity;
            gtdMinted += quantity;

        } else if (currentPhase == MintPhase.FCFS) {
            require(FCFSList[msg.sender], "Not on FCFS list");
            require(fcfsMintedWallets[msg.sender] + quantity <= 3, "Max FCFS mint reached");
            require(msg.value == priceFCFS * quantity, "Incorrect ETH amount");
            require(fcfsMinted + quantity <= FCFS_MAX_SUPPLY, "FCFS supply exhausted");
            fcfsMintedWallets[msg.sender] += quantity;
            fcfsMinted += quantity;

        } else if (currentPhase == MintPhase.Public) {
            require(publicMintedWallets[msg.sender] + quantity <= 4, "Max Public mint reached");
            require(msg.value == pricePublic * quantity, "Incorrect ETH amount");
            publicMintedWallets[msg.sender] += quantity;
        }

        _safeMint(msg.sender, quantity);
        emit MintExecuted(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        require(currentPhase == MintPhase.Closed, "Can only mint before any phase starts");
        require(quantity > 0, "Quantity must be greater than 0");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");
        require(ownerMinted + quantity <= 80, "Max owner mint reached"); // Limiting to 80 NFTs for owner

        ownerMinted += quantity;
        _safeMint(msg.sender, quantity);
        emit OwnerMintExecuted(msg.sender, quantity);
    }

    // URI handling
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        
        if (!revealed) {
            return placeholderURI;
        }

        string memory baseURI = _baseURI();
        uint256 realId = tokenId;
        if (offset > 0) {
            realId = (tokenId + offset) % MAX_SUPPLY;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, realId.toString(), ".json")) : "";
    }

    function reveal() external onlyOwner {
        require(!revealed, "Already revealed");
        revealed = true;
        offsetBlock = block.number + 1;
        emit Revealed();
    }

    function setOffset() external onlyOwner {
        require(revealed, "Not revealed yet");
        require(offset == 0, "Offset already set");
        require(block.number > offsetBlock, "Wait at least 1 block");
        require(block.number - offsetBlock <= 256, "Blockhash expired");
        uint256 bhash = uint256(blockhash(offsetBlock));
        require(bhash != 0, "Blockhash not available");
        offset = bhash % MAX_SUPPLY;
    }

    // Admin functions
    function setBaseURI(string calldata uri) external onlyOwner {
        require(!baseURILocked, "Base URI is locked");
        baseTokenURI = uri;
        emit BaseURISet(uri);
    }

    function setPlaceholderURI(string calldata uri) external onlyOwner {
        require(!revealed, "Already revealed");
        placeholderURI = uri;
        emit PlaceholderURISet(uri);
    }

    function lockBaseURI() external onlyOwner {
        baseURILocked = true;
    }

    function setMintPhase(uint256 phase) external onlyOwner {
        require(phase <= uint256(MintPhase.Public), "Invalid mint phase");
        MintPhase newPhase = MintPhase(phase);
        
        // Reset time tracking for the new phase
        phaseStartTime[newPhase] = block.timestamp;
        phaseEndedByTime[newPhase] = false;
        
        currentPhase = newPhase;
        emit MintPhaseChanged(phase);
    }

    function setOGList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            OGList[addresses[i]] = true;
        }
        emit OGListAdded(addresses);
    }

    function setGTDList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            GTDList[addresses[i]] = true;
        }
        emit GTDListAdded(addresses);
    }

    function setFCFSList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            FCFSList[addresses[i]] = true;
        }
        emit FCFSListAdded(addresses);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Treasury cannot be zero address");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit RoyaltyUpdated(receiver, feeNumerator);
    }

    function setPriceFCFS(uint256 _price) external onlyOwner {
        priceFCFS = _price;
        emit PriceFCFSUpdated(_price);
    }

    function setPricePublic(uint256 _price) external onlyOwner {
        pricePublic = _price;
        emit PricePublicUpdated(_price);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Withdraw failed");
        emit WithdrawExecuted(treasury, balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Internal functions
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getPhaseStatus() external view returns (
        bool isActive,
        bool hasEndedByTime,
        bool hasEndedBySupply,
        uint256 timeRemaining,
        uint256 supplyRemaining
    ) {
        if (currentPhase == MintPhase.Closed || currentPhase == MintPhase.Public) {
            return (currentPhase != MintPhase.Closed, false, false, 0, 0);
        }

        uint256 currentSupply;
        uint256 maxSupply;
        
        if (currentPhase == MintPhase.OG) {
            currentSupply = ogMinted;
            maxSupply = OG_MAX_SUPPLY;
        } else if (currentPhase == MintPhase.GTD) {
            currentSupply = gtdMinted;
            maxSupply = GTD_MAX_SUPPLY;
        } else if (currentPhase == MintPhase.FCFS) {
            currentSupply = fcfsMinted;
            maxSupply = FCFS_MAX_SUPPLY;
        }

        bool endedByTime = phaseEndedByTime[currentPhase] || 
            (block.timestamp >= phaseStartTime[currentPhase] + PHASE_DURATION);
        bool endedBySupply = currentSupply >= maxSupply;
        
        uint256 remainingTime = 0;
        if (!endedByTime) {
            uint256 endTime = phaseStartTime[currentPhase] + PHASE_DURATION;
            if (endTime > block.timestamp) {
                remainingTime = endTime - block.timestamp;
            }
        }

        return (
            currentPhase != MintPhase.Closed && !endedByTime && !endedBySupply,
            endedByTime,
            endedBySupply,
            remainingTime,
            maxSupply - currentSupply
        );
    }
}