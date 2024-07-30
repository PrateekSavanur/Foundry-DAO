// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Company is Ownable {
    string private headline;

    event HeadlineUpdated(string newHeadline);

    constructor() Ownable(msg.sender) {}

    function getHeadline() public view returns (string memory) {
        return headline;
    }

    function updateHeadline(string memory newHeadline) public onlyOwner {
        headline = newHeadline;
        emit HeadlineUpdated(newHeadline);
    }
}
