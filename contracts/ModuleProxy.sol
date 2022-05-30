// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import "./IModuleProxy.sol";

contract ModuleProxy is IModuleProxy {
    event NewImplementation(address oldImplementation, address newImplementation);
    event NewAdmin(address indexed newAdmin);

    address public implementation;
    address public admin;

    function setImplementation(address _imp) external override {
        require(admin == msg.sender, "MP: only admin can setImplementation");
        address old = implementation;
        implementation = _imp;
        emit NewImplementation(old, implementation);
    }

    constructor(address _admin) {
        admin = _admin;
    }

    function setAdmin(address _admin) public {
        require(admin == msg.sender, "MP: only admin can setAdmin");
        admin = _admin;
        emit NewAdmin(admin);
    }

    function getImplementation() external view returns (address) {
        return implementation;
    }

    function _delegate(address _imp) internal virtual {
        assembly {
            // calldatacopy(t, f, s)
            // copy s bytes from calldata at position f to mem at position t
            calldatacopy(0, 0, calldatasize())

            // delegatecall(g, a, in, insize, out, outsize)
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error and 1 on success
            let result := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)

            // returndatacopy(t, f, s)
            // copy s bytes from returndata at position f to mem at position t
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // revert(p, s)
                // end execution, revert state changes, return data mem[p…(p+s))
                revert(0, returndatasize())
            }
            default {
                // return(p, s)
                // end execution, return data mem[p…(p+s))
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate(implementation);
    }
}

/*
contract V1 {
    address public implementation;
    uint public x;

    function initialize() public {
    }
    function inc() external {
        x += 1;
    }
}

contract V2 {
    address public implementation;
    uint public x;

    function initialize() public {}
    function inc() external {
        x += 1;
    }

    function dec() external {
        x -= 1;
    }
}
*/
