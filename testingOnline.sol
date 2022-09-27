pragma solidity ^0.8.7;

contract testingOnline3 {

    struct Exam {
        address owner; // Lưu địa chỉ của người tổ chức kỳ thi
        uint reward;    // Phần thưởng của kỳ thi
        string answer;  // Lưu đáp án của kỳ thi
        State state;    // Lưu trạng thái của kỳ thi
    }

    struct Submission { // Lưu bài thi của người dự thi
        address owner;  // Lưu địa chỉ của người submit bài thi 
        uint examCode;  // Mã kỳ thi submit
        string answer;  // Đáp án submit
        uint submitTime;    // Thời gian submit
    }
    struct Winner {
        address winnerAddr; // Địa chỉ của người chiến thắng
        uint submitTime;    // Thời gian submit
    }

    address public contractOwner; // Biến lưu địa chỉ chủ hợp đồng
    enum State { SUBMITTEST, SUBMITANS, GETDEPOSIT, END } // Các trạng thái của kỳ thi
    uint public examFund;   // Qũy lệ phí thi của hợp đồng
    uint[] public examCode; // Mảng lưu các mã kỳ thi hiện có
    Submission[] public submissions;    // Mảng lưu bài thi submit
    mapping(uint => Exam) public exams; // Lưu kỳ thi theo mã kỳ thi

    constructor(){
        contractOwner = msg.sender; // Lưu địa chỉ của người tạo hợp đồng
    }


    uint randNonce = 0;

    function randCode() internal returns(uint){ // Hàm random tạo mã kỳ thi
        randNonce++; 
        return uint(keccak256(abi.encodePacked(block.timestamp,
                                          msg.sender,
                                          randNonce))) % 1000000;
    }

    function createExams(uint _reward) public payable{ // Hàm tạo kỳ thi 
        require(msg.value == 1 ether);
        uint _examCode = randCode();
        examCode.push(_examCode);
        exams[_examCode].owner = msg.sender;
        exams[_examCode].reward = _reward;
        exams[_examCode].state = State.SUBMITTEST;
        examFund += msg.value;
    }

    function submitTest(uint _codeExam,string memory _answer) public payable check(State.SUBMITTEST, false, _codeExam, true){ // Hàm submit bài thi
        require(msg.value == 1 ether);  
        Submission memory submission;
        submission.owner = msg.sender;
        submission.examCode = _codeExam;
        submission.answer = _answer;
        submission.submitTime = block.timestamp;
        submissions.push(submission);
        examFund += msg.value;
    }

    function endSubmit(uint _examCode) public check(State.SUBMITTEST, true, _examCode, true){ // Hàm kết thúc thời gian submit
        exams[_examCode].state = State.SUBMITANS; // Chuyển trạng thái kỳ thi sang submit đáp án
    }

    function submitAnswer(uint _examCode, string memory _answer) public payable check(State.SUBMITANS, true, _examCode, true) { // Hàm submit đáp án của kỳ thi
        require(msg.value == exams[_examCode].reward);
        exams[_examCode].answer = _answer;
        exams[_examCode].state = State.GETDEPOSIT;
    }
    Winner[] winners;
    Winner[] clear;

    function pickWinner(uint _examCode) public check(State.GETDEPOSIT, true, _examCode, true){ // Hàm chọn người chiến thằng theo mã kỳ thi
        require(exams[_examCode].owner == msg.sender);
        for (uint i = 0; i < submissions.length ; i++) {
            if(submissions[i].examCode == _examCode){
                if((keccak256(abi.encodePacked(submissions[i].answer))) == (keccak256(abi.encodePacked(exams[_examCode].answer)))){
                    Winner memory winner;
                    winner.winnerAddr = submissions[i].owner;
                    winner.submitTime = submissions[i].submitTime;
                    winners.push(winner);
                }
            }
        }
        uint tg;
        for (uint i = 0; i < winners.length - 1; i++){
            for (uint j = i + 1; j < winners.length; j ++){
                if(winners[i].submitTime > winners[j].submitTime){
                    tg = winners[i].submitTime;
                    winners[i].submitTime = winners[j].submitTime;
                    winners[j].submitTime = tg;
                }
            }
        } 
        if(winners.length >= 10) {
            uint _reward = exams[_examCode].reward / 10;
            for(uint i = 0; i < 10; i++){
                payable(winners[i].winnerAddr).transfer(_reward);
            }
        }else {
            for(uint i = 0; i <winners.length; i++) {
                uint _reward = exams[_examCode].reward / winners.length;
                payable(winners[i].winnerAddr).transfer(_reward);
            }
        }
        winners = clear;
        exams[_examCode].state = State.END;
    }

    function getFund() public { // Hàm rút quỹ lệ phí thi
        require(msg.sender == contractOwner);
        payable(contractOwner).transfer(examFund); 
    }

    modifier check(State requireState, bool ownerRequire,uint _examCode,bool examCodeExist) // Hàm check điều kiện 
    { 
        require(exams[_examCode].state == requireState);
        if(ownerRequire) {
            require(exams[_examCode].owner == msg.sender);
        }
        if(examCodeExist) {
            uint count = 0 ;
            for(uint i = 0; i < examCode.length; i++){
                if(_examCode == examCode[i]){
                    count++;
                }
            }
            require(count == 1);
        }
        _;
    }
    
}