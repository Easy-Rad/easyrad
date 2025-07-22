#Requires AutoHotkey v2.0

class RequestData {
    __New(request) {
        this.modality := request["modality"]
        this.exam := request["exam"]
    }
    toString() => "Modality: " this.modality "`nExam: " this.exam
}

class Result {
    __New(result) {
        this.body_part := result["body_part"]
        this.code := result["code"]
        this.exam := result["exam"]
        this.custom := result["custom"]
    }
    toString() => "Body part: " this.body_part "`nExam code: " this.code "`nExam: " this.exam "`nCustom: " this.custom
}

class Response {
	__New(response) {
        this.request := RequestData(response["request"])
        this.result := response["result"] && Result(response["result"])
	}

	toString() => "Request: [" this.request.toString() "]`nResult: [" (this.result ? this.result.toString() : "none") "]"

}