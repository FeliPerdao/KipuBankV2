// SPDX-License-Identifier: MIT
pragma solidity >0.8.28;

/**
 * @title KipuBank Contract
 * @author FeliPerdao
 * @notice Contract for token storage and deposit/withdraw functions similar to a bank. 
 *         There are limits on withdrawals per transaction. 
 *         The contract has a global deposit limit (bankCap) and it tracks the number of deposits and withdrawals.
 * @dev This contract is for learning purposes only.
 * @custom:security Do not use this code in production.
 */

///@notice interface for Chainlink oracle
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundID,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract KipuBank {

    /*///////////////////////////////////////////
    ================ IMMUTABLES =================
    ///////////////////////////////////////////*/

    uint256 immutable public i_withdrawLimit; // withdrawal limit
    uint256 immutable public i_bankCap; // global bank limit

    /*///////////////////////////////////////////
    ============= STATE VARIABLES ===============
    ///////////////////////////////////////////*/

    ///@notice contract owner for access control
    address public s_owner;

    ///@notice instance of Chainlink price feed
    AggregatorV3Interface public s_priceFeed;

    ///@notice mapping representing personal accounts for each user
    mapping(address user => uint256 balance) public s_vaults;

    ///@notice nested mapping that stores user transactions: user -> txId -> amount
    mapping(address user => mapping(uint256 txId => uint256 amount)) public s_userTxHistory;

    ///@notice total balance stored in the bank (all users combined)
    uint256 public s_totalBalance;

    ///@notice global counters for successful deposits and withdrawals
    uint256 public s_depositCount;
    uint256 public s_withdrawalCount;

    /*///////////////////////////////////////////
    ================= EVENTS ====================
    ///////////////////////////////////////////*/

    ///@notice events emitted for every successful deposit or withdrawal
    event DepositPerformed(address indexed user, uint256 amount, uint256 newVaultBalance);
    event WithdrawalPerformed(address indexed user, uint256 amount, uint256 newVaultBalance);

    ///@notice events for access control and oracle updates
    event OracleUpdated(address indexed oracle);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /*///////////////////////////////////////////
    ================= ERRORS ====================
    ///////////////////////////////////////////*/

    ///@notice revert when a deposit attempt exceeds bankCap
    error BankCapExceeded(uint256 attemptedTotal, uint256 bankCap);

    ///@notice revert when the requested withdrawal exceeds the per-transaction limit
    error WithdrawalLimitExceeded(uint256 attemptedWithdraw, uint256 limit);

    ///@notice revert when the requested withdrawal exceeds the account balance
    error InsufficientFunds(address user, uint256 attemptedWithdraw, uint256 balance);

    ///@notice error when ETH transfer fails
    error TransactionFailed(bytes reason);

    ///@notice revert when a reentrancy attack is detected
    error ReentrancyDetected();

    ///@notice revert when caller is not the contract owner
    error NotOwner(address caller);

    /*///////////////////////////////////////////
    ============= REENTRANCY GUARD ==============
    ///////////////////////////////////////////*/

    uint256 private s_status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier nonReentrant() {
        if (s_status == _ENTERED) revert ReentrancyDetected();
        s_status = _ENTERED;
        _;
        s_status = _NOT_ENTERED;
    }

    ///@notice restricts function access to the contract owner
    modifier onlyOwner() {
        if (msg.sender != s_owner) revert NotOwner(msg.sender);
        _;
    }

    /*///////////////////////////////////////////
    ================ CONSTRUCTOR ================
    ///////////////////////////////////////////*/

    /**
     * @notice Contract constructor
     * @param _withdrawLimit maximum withdrawal per transaction (wei)
     * @param _bankCap global deposit limit (wei)
     * @param _oracleAddress Chainlink oracle address
     */
    constructor(uint256 _withdrawLimit, uint256 _bankCap, address _oracleAddress) {
        i_withdrawLimit = _withdrawLimit;
        i_bankCap = _bankCap;
        s_status = _NOT_ENTERED;
        s_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_oracleAddress);
    }

    /*///////////////////////////////////////////
    ============ FALLBACK / RECEIVE ============
    ///////////////////////////////////////////*/

    ///@notice allows receiving ETH directly and treats it as a deposit
    receive() external payable{
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    /*///////////////////////////////////////////
    ================= FUNCTIONS =================
    ///////////////////////////////////////////*/

    /**
     * @notice Deposit ETH into the "msg.sender" account
     * @dev follows the checks-effects-interactions pattern; reverts if the total bank balance exceeds the limit
     */
    function deposit() public payable {
        // -- checks --
        uint256 newTotalBalance = s_totalBalance + msg.value;
        if (newTotalBalance > i_bankCap) revert BankCapExceeded(newTotalBalance, i_bankCap);

        // -- effects --
        uint256 newVaultBalance = s_vaults[msg.sender] + msg.value;
        s_vaults[msg.sender] = newVaultBalance;
        s_totalBalance = newTotalBalance;
        s_depositCount++;

        // store transaction in nested mapping
        s_userTxHistory[msg.sender][s_depositCount] = msg.value;

        // -- interactions --
        emit DepositPerformed(msg.sender, msg.value, newVaultBalance);
    }

    /**
        * @notice ETH withdrawal
        * @param _amount value to withdraw (wei)
    */
    function withdraw(uint256 _amount) external nonReentrant {
        // -- checks --
        if (_amount > i_withdrawLimit) revert WithdrawalLimitExceeded(_amount, i_withdrawLimit);
        uint256 vaultBalance = s_vaults[msg.sender];
        if (_amount > vaultBalance) revert InsufficientFunds(msg.sender, _amount, vaultBalance);

        // -- effects --
        uint256 newVaultBalance;
        unchecked { newVaultBalance = vaultBalance - _amount; }
        s_vaults[msg.sender] = newVaultBalance;
        s_totalBalance -= _amount;
        s_withdrawalCount++;

        // store transaction in nested mapping
        s_userTxHistory[msg.sender][s_withdrawalCount] = _amount;

        // -- interactions --
        emit WithdrawalPerformed(msg.sender, _amount, newVaultBalance);
        _transferEth(msg.sender, _amount);
    }

    /**
     * @notice ETH transfer using call
     * @param _to withdrawal destination
     * @param _amount amount to transfer in wei
     * @dev revert if transfer fails
     */
    function _transferEth(address _to, uint256 _amount) private {
        (bool success, bytes memory err) = _to.call{value: _amount}("");
        if (!success) revert TransactionFailed(err);
    }

    /**
     * @notice Query a user's account balance
     * @param _user address to query
     * @return balance account balance in wei for _user
     */
    function getVaultBalance(address _user) external view returns (uint256 balance) {
        return s_vaults[_user];
    }

    /**
     * @notice converts between decimals
     * @param amount token amount
     * @param fromDecimals original decimals
     * @param toDecimals target decimals
     */
    function normalizeDecimals(uint256 amount, uint8 fromDecimals, uint8 toDecimals)
        public pure returns (uint256)
    {
        if (fromDecimals == toDecimals) return amount;
        if (fromDecimals > toDecimals)
            return amount / (10 ** (fromDecimals - toDecimals));
        else
            return amount * (10 ** (toDecimals - fromDecimals));
    }

    /**
     * @notice retrieves the latest price from the Chainlink oracle
     * @return price current price from oracle feed
     */
    function getLatestPrice() public view returns (int256 price) {
        (, price,,,) = s_priceFeed.latestRoundData();
        return price;
    }

    /**
     * @notice returns the USD value of an ETH deposit based on Chainlink price
     * @param ethAmount amount in wei
     * @return usdValue estimated USD value
     */
    function getDepositValueInUSD(uint256 ethAmount) public view returns (uint256 usdValue) {
        uint256 ethPrice = uint256(getLatestPrice());
        usdValue = (ethAmount * ethPrice) / 1e8; // assuming Chainlink 8 decimals
    }

    /**
     * @notice converts an amount in wei to ether units
     * @param amountWei amount in wei
     * @return amountEth equivalent in ether
     */
    function convertToEth(uint256 amountWei) public pure returns (uint256 amountEth) {
        return amountWei / 1e18;
    }

    /**
     * @notice converts an amount in ether to wei units
     * @param amountEth amount in ether
     * @return amountWei equivalent in wei
     */
    function convertFromEth(uint256 amountEth) public pure returns (uint256 amountWei) {
        return amountEth * 1e18;
    }

    /*///////////////////////////////////////////
    ========== ACCESS / ORACLE FUNCTIONS =========
    ///////////////////////////////////////////*/

    /**
     * @notice changes the contract owner
     * @param newOwner new owner address
     */
    function changeOwner(address newOwner) external onlyOwner {
        emit OwnerChanged(s_owner, newOwner);
        s_owner = newOwner;
    }

    /**
     * @notice updates the Chainlink oracle address
     * @param _newOracle new oracle contract address
     */
    function updateOracle(address _newOracle) external onlyOwner {
        s_priceFeed = AggregatorV3Interface(_newOracle);
        emit OracleUpdated(_newOracle);
    }

}