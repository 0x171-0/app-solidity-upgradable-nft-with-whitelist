// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*  
Transparent upgradable proxy pattern
 Topics
 - Intro(Wrong way): implementation 的 storage 的排序 跟 proxy 不同，會造成問題
 - Return data from fallback
 - Storage for implementation and admin
 - Seperate user / admin interfaces
 - Proxy admin
 - Demo
 */

contract CounterV1 {
    // 💥 出錯：implementation 的 storage 跟 proxy 不同
    // implementation 的 storage 必須跟 proxy 相同，必須加上下面兩行
    // address public implementation;
    // address public public admin;
    uint public count;

    function inc() external {
        count += 1;
    }
}

contract CounterV2 {
    // 💥 出錯：implementation 的 storage 跟 proxy 不同
    // implementation 的 storage 必須跟 proxy 相同，必須加上下面兩行
    // address public implementation;
    // address public public admin;
    uint public count;

    function inc() external {
        count += 1;
    }

    function dec() external {
        count -= 1;
    }
}

// 部署之後，我們可以使用 Counter 的 interface、BuggyProxy 的地址，這樣就可以透過 BuggyProxy 合約 delegate call Counter 了
contract BuggyProxy {
    // 這個 Proxy 有兩個問題：
    // 1. storage not same with the implementation contract
    // 2. fallback function can't get return data
    address public implementation;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    // 我們要想辦法實作，雖然 _delegate 沒有指定 return 值，因為我們是 call 外部，所以不知道 return 會是什麼，所以沒辦法在一開始就先定義 return 值
    // 所以我們只能透過 assembly 做到，可以參考 openzeplin 的實作方式
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol
    function _delegate() private {
        (bool ok, bytes memory res) = implementation.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     * 為了要解決上面的 function 沒辦法 return function 的問題
     */
    function _delegate(address _implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.

            // calldatacopy(t, f, s) - copy s bytes from calldata at position f to mem at position t
            // calldatasize() - size of call data in bytes
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.

            // delegatecall(g, a, in, insize, out, outsize) -
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error (eg. out of gas) and 1 on success
            let result := delegatecall(
                gas(),
                _implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            // returndatacopy(t, f, s) - copy s bytes from returndata at position f to mem at position t
            // returndatasize() - size of the last returndata
            // 把 return data 複製到 memory 當中
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                // revert(p, s) - end execution, revert state changes, return data mem[p…(p+s))
                revert(0, returndatasize())
            }
            default {
                // return(p, s) - end execution, return data mem[p…(p+s))
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    function upgradeTo(address _implementation) external {
        require(msg.sender == admin, "not authorized");
        implementation = _implementation;
    }
}

// store address in any slot wewant
// refs: https://www.youtube.com/watch?v=RcyCW1nigog
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        assembly {
            // return the pointer to storage are located at start from the the input
            r.slot := slot
        }
    }
}

contract TestSlot {
    bytes32 public constant slot = keccak256("TEST_SLOT");

    function getSlot() external view returns (address) {
        return StorageSlot.getAddressSlot(slot).value;
    }

    function writeSlot(address _addr) external {
        // value 就是 AddressSlot 定義的地址
        StorageSlot.getAddressSlot(slot).value = _addr;
    }
}
