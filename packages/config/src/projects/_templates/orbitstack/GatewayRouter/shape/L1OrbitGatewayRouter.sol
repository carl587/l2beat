// SPDX-License-Identifier: Unknown
pragma solidity 0.8.16;

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract WhitelistConsumer {
    address public whitelist;

    event WhitelistSourceUpdated(address newSource);

    modifier onlyWhitelisted() {
        if (whitelist != address(0)) {
            require(Whitelist(whitelist).isAllowed(msg.sender), "NOT_WHITELISTED");
        }
        _;
    }

    function updateWhitelistSource(address newSource) external {
        require(msg.sender == whitelist, "NOT_FROM_LIST");
        whitelist = newSource;
        emit WhitelistSourceUpdated(newSource);
    }
}

abstract contract L1ArbitrumMessenger {
    event TxToL2(address indexed _from, address indexed _to, uint256 indexed _seqNum, bytes _data);

    struct L2GasParams {
        uint256 _maxSubmissionCost;
        uint256 _maxGas;
        uint256 _gasPriceBid;
    }

    function sendTxToL2CustomRefund(
        address _inbox,
        address _to,
        address _refundTo,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        L2GasParams memory _l2GasParams,
        bytes memory _data
    ) internal returns (uint256) {
        // alternative function entry point when struggling with the stack size
        return
            sendTxToL2CustomRefund(
                _inbox,
                _to,
                _refundTo,
                _user,
                _l1CallValue,
                _l2CallValue,
                _l2GasParams._maxSubmissionCost,
                _l2GasParams._maxGas,
                _l2GasParams._gasPriceBid,
                _data
            );
    }

    function sendTxToL2(
        address _inbox,
        address _to,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        L2GasParams memory _l2GasParams,
        bytes memory _data
    ) internal returns (uint256) {
        // alternative function entry point when struggling with the stack size
        return
            sendTxToL2(
                _inbox,
                _to,
                _user,
                _l1CallValue,
                _l2CallValue,
                _l2GasParams._maxSubmissionCost,
                _l2GasParams._maxGas,
                _l2GasParams._gasPriceBid,
                _data
            );
    }

    function sendTxToL2CustomRefund(
        address _inbox,
        address _to,
        address _refundTo,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal returns (uint256) {
        uint256 seqNum = _createRetryable(
            _inbox,
            _to,
            _refundTo,
            _user,
            _l1CallValue,
            _l2CallValue,
            _maxSubmissionCost,
            _maxGas,
            _gasPriceBid,
            _data
        );
        emit TxToL2(_user, _to, seqNum, _data);
        return seqNum;
    }

    function sendTxToL2(
        address _inbox,
        address _to,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal returns (uint256) {
        return
            sendTxToL2CustomRefund(
                _inbox,
                _to,
                _user,
                _user,
                _l1CallValue,
                _l2CallValue,
                _maxSubmissionCost,
                _maxGas,
                _gasPriceBid,
                _data
            );
    }

    function getBridge(address _inbox) internal view returns (IBridge) {
        return IInbox(_inbox).bridge();
    }

    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function getL2ToL1Sender(address _inbox) internal view returns (address) {
        IOutbox outbox = IOutbox(getBridge(_inbox).activeOutbox());
        address l2ToL1Sender = outbox.l2ToL1Sender();

        require(l2ToL1Sender != address(0), "NO_SENDER");
        return l2ToL1Sender;
    }

    /**
     * @notice Calls inbox to create retryable ticket. Default implementation is for standard Eth-based rollup, but it can be overriden to create retryable in ERC20-based rollup.
     * @param _inbox address of the rollup's inbox
     * @param _to destination L2 contract address
     * @param _refundTo refund address for excess fee
     * @param _user refund address for callvalue
     * @param _totalFeeAmount amount of fees to pay, in Eth or native token, for retryable's execution
     * @param _l2CallValue call value for retryable L2 message
     * @param _maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param _gasPriceBid price bid for L2 execution
     * @param _data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function _createRetryable(
        address _inbox,
        address _to,
        address _refundTo,
        address _user,
        uint256 _totalFeeAmount,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal virtual returns (uint256) {
        return
            IInbox(_inbox).createRetryableTicket{ value: _totalFeeAmount }(
                _to,
                _l2CallValue,
                _maxSubmissionCost,
                _refundTo,
                _user,
                _maxGas,
                _gasPriceBid,
                _data
            );
    }
}

abstract contract TokenGateway is ITokenGateway {
    using Address for address;

    address public counterpartGateway;
    address public router;

    // This modifier is overriden in gateways to validate the message sender
    // For L1 to L2 messages need to be validated against the aliased counterpartGateway
    // For L2 to L1 messages need to be validated against the bridge and L2ToL1Sender
    // prettier-ignore
    modifier onlyCounterpartGateway() virtual;

    function _initialize(address _counterpartGateway, address _router) internal virtual {
        // This initializes internal variables of the abstract contract it can be chained together with other functions.
        // It is virtual so subclasses can override or wrap around this logic.
        // An example where this is useful is different subclasses that validate the router address differently
        require(_counterpartGateway != address(0), "INVALID_COUNTERPART");
        require(counterpartGateway == address(0), "ALREADY_INIT");
        counterpartGateway = _counterpartGateway;
        router = _router;
    }

    function isRouter(address _target) internal view returns (bool isTargetRouter) {
        return _target == router;
    }

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20)
        public
        view
        virtual
        override
        returns (address);
}

interface IGatewayRouter is ITokenGateway {
    function defaultGateway() external view returns (address gateway);

    event TransferRouted(
        address indexed token,
        address indexed _userFrom,
        address indexed _userTo,
        address gateway
    );

    event GatewaySet(address indexed l1Token, address indexed gateway);
    event DefaultGatewayUpdated(address newDefaultGateway);

    function getGateway(address _token) external view returns (address gateway);
}

library ProxyUtil {
    function getProxyAdmin() internal view returns (address admin) {
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/proxy/TransparentUpgradeableProxy.sol#L48
        // Storage slot with the admin of the proxy contract.
        // This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
        bytes32 slot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        assembly {
            admin := sload(slot)
        }
    }
}

abstract contract GatewayRouter is TokenGateway, IGatewayRouter {
    using Address for address;

    address internal constant ZERO_ADDR = address(0);
    address internal constant DISABLED = address(1);

    mapping(address => address) public l1TokenToGateway;
    address public override defaultGateway;

    function postUpgradeInit() external {
        // it is assumed the L2 Arbitrum Gateway contract is behind a Proxy controlled by a proxy admin
        // this function can only be called by the proxy admin contract
        address proxyAdmin = ProxyUtil.getProxyAdmin();
        require(msg.sender == proxyAdmin, "NOT_FROM_ADMIN");
        // this has no other logic since the current upgrade doesn't require this logic
    }

    function _initialize(
        address _counterpartGateway,
        address _router,
        address _defaultGateway
    ) internal {
        // if you are a router, you can't have a router
        require(_router == address(0), "BAD_ROUTER");
        TokenGateway._initialize(_counterpartGateway, _router);
        // default gateway can have 0 address
        defaultGateway = _defaultGateway;
    }

    function finalizeInboundTransfer(
        address, /* _token */
        address, /* _from */
        address, /* _to */
        uint256, /* _amount */
        bytes calldata /* _data */
    ) external payable virtual override {
        revert("ONLY_OUTBOUND_ROUTER");
    }

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable virtual override returns (bytes memory) {
        // this function is kept instead of delegating to outboundTransferCustomRefund to allow
        // compatibility with older gateways that did not implement outboundTransferCustomRefund
        address gateway = getGateway(_token);
        bytes memory gatewayData = GatewayMessageHandler.encodeFromRouterToGateway(
            msg.sender,
            _data
        );

        emit TransferRouted(_token, msg.sender, _to, gateway);
        return
            ITokenGateway(gateway).outboundTransfer{ value: msg.value }(
                _token,
                _to,
                _amount,
                _maxGas,
                _gasPriceBid,
                gatewayData
            );
    }

    function getOutboundCalldata(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) public view virtual override returns (bytes memory) {
        address gateway = getGateway(_token);
        return TokenGateway(gateway).getOutboundCalldata(_token, _from, _to, _amount, _data);
    }

    function getGateway(address _token) public view virtual override returns (address gateway) {
        gateway = l1TokenToGateway[_token];

        if (gateway == ZERO_ADDR) {
            // if no gateway value set, use default gateway
            gateway = defaultGateway;
        }

        if (gateway == DISABLED || !gateway.isContract()) {
            // not a valid gateway
            return ZERO_ADDR;
        }

        return gateway;
    }

    function calculateL2TokenAddress(address l1ERC20)
        public
        view
        virtual
        override(TokenGateway, ITokenGateway)
        returns (address)
    {
        address gateway = getGateway(l1ERC20);
        if (gateway == ZERO_ADDR) {
            return ZERO_ADDR;
        }
        return TokenGateway(gateway).calculateL2TokenAddress(l1ERC20);
    }
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface ITokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) external view returns (address);

    function getOutboundCalldata(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external view returns (bytes memory);
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IL1GatewayRouter is ITokenGateway, IERC165 {
    /**
     * @notice Deposit ERC20 token from Ethereum into Arbitrum using the registered or otherwise default gateway
     * @dev Some legacy gateway might not have the outboundTransferCustomRefund method and will revert, in such case use outboundTransfer instead
     *      L2 address alias will not be applied to the following types of addresses on L1:
     *      - an externally-owned account
     *      - a contract in construction
     *      - an address where a contract will be created
     *      - an address where a contract lived, but was destroyed
     * @param _token L1 address of ERC20
     * @param _refundTo Account, or its L2 alias if it have code in L1, to be credited with excess gas refund in L2
     * @param _to Account to be credited with the tokens in the L2 (can be the user's L2 account or a contract), not subject to L2 aliasing
                  This account, or its L2 alias if it have code in L1, will also be able to cancel the retryable ticket and receive callvalue refund
     * @param _amount Token Amount
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param _gasPriceBid Gas price for L2 execution
     * @param _data encoded data from router and user
     * @return res abi encoded inbox sequence number
     */
    function outboundTransferCustomRefund(
        address _token,
        address _refundTo,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    /**
     * @notice Allows L1 Token contract to trustlessly register its gateway.
     * @param _gateway l1 gateway address
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @param _creditBackAddress address for crediting back overpayment of _maxSubmissionCost
     * @return Retryable ticket ID
     */
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) external payable returns (uint256);

    /**
     * @notice Allows L1 Token contract to trustlessly register its gateway. (other setGateway method allows excess eth recovery from _maxSubmissionCost and is recommended)
     * @param _gateway l1 gateway address
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @return Retryable ticket ID
     */
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable returns (uint256);

    function owner() external view returns (address);

    function inbox() external view returns (address);
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library GatewayMessageHandler {
    // these are for communication from L1 to L2 gateway

    function encodeToL2GatewayMsg(bytes memory gatewayData, bytes memory callHookData)
        internal
        pure
        returns (bytes memory res)
    {
        res = abi.encode(gatewayData, callHookData);
    }

    function parseFromL1GatewayMsg(bytes calldata _data)
        internal
        pure
        returns (bytes memory gatewayData, bytes memory callHookData)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        (gatewayData, callHookData) = abi.decode(_data, (bytes, bytes));
    }

    // these are for communication from L2 to L1 gateway

    function encodeFromL2GatewayMsg(uint256 exitNum, bytes memory callHookData)
        internal
        pure
        returns (bytes memory res)
    {
        res = abi.encode(exitNum, callHookData);
    }

    function parseToL1GatewayMsg(bytes calldata _data)
        internal
        pure
        returns (uint256 exitNum, bytes memory callHookData)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        (exitNum, callHookData) = abi.decode(_data, (uint256, bytes));
    }

    // these are for communication from router to gateway

    function encodeFromRouterToGateway(address _from, bytes calldata _data)
        internal
        pure
        returns (bytes memory res)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        return abi.encode(_from, _data);
    }

    function parseFromRouterToGateway(bytes calldata _data)
        internal
        pure
        returns (address, bytes memory res)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        return abi.decode(_data, (address, bytes));
    }
}

contract L1GatewayRouter is
    WhitelistConsumer,
    L1ArbitrumMessenger,
    GatewayRouter,
    ERC165,
    IL1GatewayRouter
{
    using Address for address;

    address public override owner;
    address public override inbox;

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function initialize(
        address _owner,
        address _defaultGateway,
        address, // was _whitelist, now unused
        address _counterpartGateway,
        address _inbox
    ) public {
        GatewayRouter._initialize(_counterpartGateway, address(0), _defaultGateway);
        owner = _owner;
        WhitelistConsumer.whitelist = address(0);
        inbox = _inbox;
    }

    function setDefaultGateway(
        address newL1DefaultGateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable virtual onlyOwner returns (uint256) {
        return
            _setDefaultGateway(
                newL1DefaultGateway,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                msg.value
            );
    }

    function _setDefaultGateway(
        address newL1DefaultGateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 feeAmount
    ) internal returns (uint256) {
        defaultGateway = newL1DefaultGateway;

        emit DefaultGatewayUpdated(newL1DefaultGateway);

        address l2NewDefaultGateway;

        if (newL1DefaultGateway != address(0)) {
            l2NewDefaultGateway = TokenGateway(newL1DefaultGateway).counterpartGateway();
        }

        bytes memory data = abi.encodeWithSelector(
            L2GatewayRouter.setDefaultGateway.selector,
            l2NewDefaultGateway
        );

        return
            sendTxToL2(
                inbox,
                counterpartGateway,
                msg.sender,
                feeAmount,
                0,
                L2GasParams({
                    _maxSubmissionCost: _maxSubmissionCost,
                    _maxGas: _maxGas,
                    _gasPriceBid: _gasPriceBid
                }),
                data
            );
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        // set newOwner to address(1) to disable owner and keep `initialize` safe
        owner = newOwner;
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its gateway. (other setGateway method allows excess eth recovery from _maxSubmissionCost and is recommended)
     * @param _gateway l1 gateway address
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @return Retryable ticket ID
     */
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable virtual override returns (uint256) {
        return setGateway(_gateway, _maxGas, _gasPriceBid, _maxSubmissionCost, msg.sender);
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its gateway.
     * @param _gateway l1 gateway address
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @param _creditBackAddress address for crediting back overpayment of _maxSubmissionCost
     * @return Retryable ticket ID
     */
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) public payable virtual override returns (uint256) {
        return
            _setGatewayWithCreditBack(
                _gateway,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _creditBackAddress,
                msg.value
            );
    }

    function _setGatewayWithCreditBack(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress,
        uint256 feeAmount
    ) internal returns (uint256) {
        require(
            ArbitrumEnabledToken(msg.sender).isArbitrumEnabled() == uint8(0xb1),
            "NOT_ARB_ENABLED"
        );

        require(_gateway.isContract(), "NOT_TO_CONTRACT");

        address currGateway = getGateway(msg.sender);
        if (currGateway != address(0) && currGateway != defaultGateway) {
            // if gateway is already set to a non-default gateway, don't allow it to set a different gateway
            require(currGateway == _gateway, "NO_UPDATE_TO_DIFFERENT_ADDR");
        }

        address[] memory _tokenArr = new address[](1);
        _tokenArr[0] = address(msg.sender);

        address[] memory _gatewayArr = new address[](1);
        _gatewayArr[0] = _gateway;

        return
            _setGateways(
                _tokenArr,
                _gatewayArr,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _creditBackAddress,
                feeAmount
            );
    }

    function setGateways(
        address[] memory _token,
        address[] memory _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable virtual onlyOwner returns (uint256) {
        // it is assumed that token and gateway are both contracts
        // require(_token[i].isContract() && _gateway[i].isContract(), "NOT_CONTRACT");
        return
            _setGateways(
                _token,
                _gateway,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                msg.sender,
                msg.value
            );
    }

    function _setGateways(
        address[] memory _token,
        address[] memory _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress,
        uint256 feeAmount
    ) internal returns (uint256) {
        require(_token.length == _gateway.length, "WRONG_LENGTH");

        for (uint256 i = 0; i < _token.length; i++) {
            l1TokenToGateway[_token[i]] = _gateway[i];
            emit GatewaySet(_token[i], _gateway[i]);
            // overwrite memory so the L2 router receives the L2 address of each gateway
            if (_gateway[i] != address(0) && _gateway[i] != DISABLED) {
                // if we are assigning a gateway to the token, the address oracle of the gateway
                // must return something other than the 0 address
                // this check helps avoid misconfiguring gateways
                require(
                    TokenGateway(_gateway[i]).calculateL2TokenAddress(_token[i]) != address(0),
                    "TOKEN_NOT_HANDLED_BY_GATEWAY"
                );
                _gateway[i] = TokenGateway(_gateway[i]).counterpartGateway();
            }
        }

        bytes memory data = abi.encodeWithSelector(
            L2GatewayRouter.setGateway.selector,
            _token,
            _gateway
        );

        return
            sendTxToL2(
                inbox,
                counterpartGateway,
                _creditBackAddress,
                feeAmount,
                0,
                L2GasParams({
                    _maxSubmissionCost: _maxSubmissionCost,
                    _maxGas: _maxGas,
                    _gasPriceBid: _gasPriceBid
                }),
                data
            );
    }

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable override(GatewayRouter, ITokenGateway) returns (bytes memory) {
        return super.outboundTransfer(_token, _to, _amount, _maxGas, _gasPriceBid, _data);
    }

    /**
     * @notice Deposit ERC20 token from Ethereum into Arbitrum using the registered or otherwise default gateway
     * @dev Some legacy gateway might not have the outboundTransferCustomRefund method and will revert, in such case use outboundTransfer instead
     *      L2 address alias will not be applied to the following types of addresses on L1:
     *      - an externally-owned account
     *      - a contract in construction
     *      - an address where a contract will be created
     *      - an address where a contract lived, but was destroyed
     * @param _token L1 address of ERC20
     * @param _refundTo Account, or its L2 alias if it have code in L1, to be credited with excess gas refund in L2
     * @param _to Account to be credited with the tokens in the L2 (can be the user's L2 account or a contract), not subject to L2 aliasing
                  This account, or its L2 alias if it have code in L1, will also be able to cancel the retryable ticket and receive callvalue refund
     * @param _amount Token Amount
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param _gasPriceBid Gas price for L2 execution
     * @param _data encoded data from router and user
     * @return res abi encoded inbox sequence number
     */
    function outboundTransferCustomRefund(
        address _token,
        address _refundTo,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable override returns (bytes memory) {
        address gateway = getGateway(_token);
        bytes memory gatewayData = GatewayMessageHandler.encodeFromRouterToGateway(
            msg.sender,
            _data
        );

        emit TransferRouted(_token, msg.sender, _to, gateway);
        // here we use `IL1ArbitrumGateway` since we don't assume all ITokenGateway implements `outboundTransferCustomRefund`
        return
            IL1ArbitrumGateway(gateway).outboundTransferCustomRefund{ value: msg.value }(
                _token,
                _refundTo,
                _to,
                _amount,
                _maxGas,
                _gasPriceBid,
                gatewayData
            );
    }

    modifier onlyCounterpartGateway() override {
        // don't expect messages from L2 router
        revert("ONLY_COUNTERPART_GATEWAY");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        // registering interfaces that is added after arb-bridge-peripherals >1.0.11
        // using function selector instead of single function interfaces to reduce bloat
        return
            interfaceId == this.outboundTransferCustomRefund.selector ||
            super.supportsInterface(interfaceId);
    }
}

contract L1OrbitGatewayRouter is L1GatewayRouter {
    using SafeERC20 for IERC20;

    /**
     * @notice Allows owner to register the default gateway.
     * @param newL1DefaultGateway default gateway address
     * @param _maxGas max gas for L2 retryable execution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param _maxSubmissionCost base submission cost for L2 retryable ticket
     * @param _feeAmount total amount of fees in native token to cover for retryable ticket costs. This amount will be transferred from user to bridge.
     * @return Retryable ticket ID
     */
    function setDefaultGateway(
        address newL1DefaultGateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 _feeAmount
    ) external onlyOwner returns (uint256) {
        return
            _setDefaultGateway(
                newL1DefaultGateway,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _feeAmount
            );
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its gateway.
     * @dev Other setGateway method allows excess eth recovery from _maxSubmissionCost and is recommended.
     * @param _gateway l1 gateway address
     * @param _maxGas max gas for L2 retryable execution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param _maxSubmissionCost base submission cost for L2 retryable ticket
     * @param _feeAmount total amount of fees in native token to cover for retryable ticket costs. This amount will be transferred from user to bridge.
     * @return Retryable ticket ID
     */
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 _feeAmount
    ) external returns (uint256) {
        return
            setGateway(_gateway, _maxGas, _gasPriceBid, _maxSubmissionCost, msg.sender, _feeAmount);
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its gateway.
     * @dev Other setGateway method allows excess eth recovery from _maxSubmissionCost and is recommended.
     * @param _gateway l1 gateway address
     * @param _maxGas max gas for L2 retryable execution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @param _creditBackAddress address for crediting back overpayment of _maxSubmissionCost
     * @param _feeAmount total amount of fees in native token to cover for retryable ticket costs. This amount will be transferred from user to bridge.
     * @return Retryable ticket ID
     */
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress,
        uint256 _feeAmount
    ) public returns (uint256) {
        return
            _setGatewayWithCreditBack(
                _gateway,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _creditBackAddress,
                _feeAmount
            );
    }

    /**
     * @notice Allows owner to register gateways for specific tokens.
     * @param _token list of L1 token addresses
     * @param _gateway list of L1 gateway addresses
     * @param _maxGas max gas for L2 retryable execution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param _maxSubmissionCost base submission cost for L2 retryable ticket
     * @param _feeAmount total amount of fees in native token to cover for retryable ticket costs. This amount will be transferred from user to bridge.
     * @return Retryable ticket ID
     */
    function setGateways(
        address[] memory _token,
        address[] memory _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 _feeAmount
    ) external onlyOwner returns (uint256) {
        return
            _setGateways(
                _token,
                _gateway,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                msg.sender,
                _feeAmount
            );
    }

    function _createRetryable(
        address _inbox,
        address _to,
        address _refundTo,
        address _user,
        uint256 _totalFeeAmount,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal override returns (uint256) {
        {
            // Transfer native token amount needed to pay for retryable fees to the inbox.
            // Fee tokens will be transferred from msg.sender
            address nativeFeeToken = IERC20Bridge(address(getBridge(_inbox))).nativeToken();
            uint256 inboxNativeTokenBalance = IERC20(nativeFeeToken).balanceOf(_inbox);
            if (inboxNativeTokenBalance < _totalFeeAmount) {
                uint256 diff = _totalFeeAmount - inboxNativeTokenBalance;
                IERC20(nativeFeeToken).safeTransferFrom(msg.sender, _inbox, diff);
            }
        }

        return
            IERC20Inbox(_inbox).createRetryableTicket(
                _to,
                _l2CallValue,
                _maxSubmissionCost,
                _refundTo,
                _user,
                _maxGas,
                _gasPriceBid,
                _totalFeeAmount,
                _data
            );
    }

    /**
     * @notice Revert 'setGateway' entrypoint which doesn't have total amount of token fees as an argument.
     */
    function setGateway(
        address,
        uint256,
        uint256,
        uint256,
        address
    ) public payable override returns (uint256) {
        revert("NOT_SUPPORTED_IN_ORBIT");
    }

    /**
     * @notice Revert 'setDefaultGateway' entrypoint which doesn't have total amount of token fees as an argument.
     */
    function setDefaultGateway(
        address,
        uint256,
        uint256,
        uint256
    ) external payable override onlyOwner returns (uint256) {
        revert("NOT_SUPPORTED_IN_ORBIT");
    }

    /**
     * @notice Revert 'setGateway' entrypoint which doesn't have total amount of token fees as an argument.
     */
    function setGateway(
        address,
        uint256,
        uint256,
        uint256
    ) external payable override returns (uint256) {
        revert("NOT_SUPPORTED_IN_ORBIT");
    }

    /**
     * @notice Revert 'setGateways' entrypoint which doesn't have total amount of token fees as an argument.
     */
    function setGateways(
        address[] memory,
        address[] memory,
        uint256,
        uint256,
        uint256
    ) external payable override onlyOwner returns (uint256) {
        revert("NOT_SUPPORTED_IN_ORBIT");
    }
}