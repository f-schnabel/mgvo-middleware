import ballerina/http;
import ballerina/http.httpscerr;
import ballerina/mime;
import ballerina/constraint;

type MgvoMiddlewareResponse MgvoResponse|
    http:ClientError|
    httpscerr:BadRequestError|
    httpscerr:UnauthorizedError|
    httpscerr:InternalServerErrorError;

@constraint:Int {
    minValue: 0,
    maxValue: 3
}
type DunningLevel int;

const Gender = {
    "factual": "x",
    "male": "m",
    "female": "w"
};

service / on new http:Listener(8080,     
    secureSocket = {
        key: {
            certFile: "../certificates/selfsigned.crt",
            keyFile: "../certificates/selfsigned.key"
        }
    }) {

    private final http:Client mgvoClient = check new ("https://www.mgvo.de/api/api_entry.php");

    function init() returns error? {
    }

    resource function get trainers(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_TRAINERS, callId);
    }

    resource function get locations(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_LOCATIONS, callId);
    }

    resource function get groups(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_GROUPS, callId);
    }

    resource function get groups/categories(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_GROUP_CATEGORIES, callId);
    }

    resource function get departments(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_DEPARTMENTS, callId);
    }

    resource function get events(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_EVENTS, callId);
    }

    # Get all members
    # + search - General search term
    # + birthdateFrom - Age/Date of birth from
    # + birthdateTo - Age/Date of birth to
    # + resignationFrom - Resignation (Austritt) from
    # + resignationTo - Resignation (Austritt) to
    # + groupId - Group ID
    # + priceGroup - Contribution group (Beitragsgruppe)
    # + directDebitPayer - Direct debit payer (Lastschriftzahler)
    # + cashPayer - Cash payer/Transfer (Barzahler/Überweiser)
    # + standingOrder - Standing order (Dauerauftrag)
    # + gender - Gender
    # + member - Member (Ausgetreten/Member)
    # + active - Active/Passive
    # + mailRecipient - Mail recipient (Mailempfänger)
    # + domestic - Domestic/Foreign (Inland/Ausland)
    # + dunningLevel - Dunning level (Mahnstufe)
    # + return - All members
    isolated resource function get members(
            @http:Header {name: "call-id"} string callId,
            @http:Header {name: "crypt-key"} string cryptKey,
            string? search,
            string? birthdateFrom,
            string? birthdateTo,
            string? resignationFrom,
            string? resignationTo,
            string? groupId,
            string? priceGroup,
            boolean? directDebitPayer,
            boolean? cashPayer,
            boolean? standingOrder,
            "factual"|"male"|"female"? gender,
            string? member,
            string? active,
            string? mailRecipient,
            string? domestic,
            DunningLevel? dunningLevel
    ) returns MgvoMiddlewareResponse|Member[] {
        map<anydata> params = {
            suchbeg: search,
            suchalterv: birthdateFrom,
            suchalterb: birthdateTo,
            suchaustrittv: resignationFrom,
            suchaustrittb: resignationTo,
            suchgruid: groupId,
            suchbeigru: priceGroup,
            lssel: directDebitPayer == true ? "1" : null,
            barsel: cashPayer == true ? "1" : null,
            dasel: standingOrder == true ? "1" : null,
            geschl: gender is null ? null : Gender[gender],
            ausgetr: member,
            aktpass: active,
            mailempf: mailRecipient,
            landsel: domestic,
            selmahnstufe: dunningLevel is null ? null : dunningLevel == 0 ? "a" : dunningLevel.toString()
        };

        var result = check self.forward(GET_MEMBERS, callId, cryptKey, params.filter(v => v !is null));

        Member[]|error r = result[result.objname].cloneWithType();
        if r is error {
            return error httpscerr:InternalServerErrorError(r.toString(), r);
        }
        return r;
    }

    resource function get members/[int id](@http:Header {name: "call-id"} string callId, @http:Header {name: "crypt-key"} string cryptKey) returns MgvoMiddlewareResponse|error {
        return self.forward(GET_MEMBERS, callId, cryptKey, {
            suchbeg: id
        });
    }

    resource function get members/[int id]/picture(@http:Header {name: "call-id"} string callId, @http:Header {name: "crypt-key"} string cryptKey) returns http:NotImplemented {
        return http:NOT_IMPLEMENTED;
        // TODO doesn't work also in the original php api
        //return self.encryptedGetMgvo(GET_MEMBERPIC, callId, cryptKey, {
        //    mgnr: id
        //});
    }

    resource function get documents(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_DOCUMENTS, callId);
    }

    resource function get documents/lists(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_DOCUMENTLISTS, callId);
    }

    resource function get prices(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_TARIFE, callId);
    }

    resource function get prices/groups(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_CONTRIBUTIONGROUPS, callId);
    }

    resource function post members(@http:Header {name: "call-id"} string callId, @http:Header string crypt\-key, @http:Payload Member payload) returns MgvoMiddlewareResponse {
        return self.forward(POST_MEMBERS, callId, crypt\-key, {
            inar: payload
        });
    }

    resource function get calendars(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_CALENDARS, callId);
    }

    resource function get calendars/trainings/canceled(@http:Header {name: "call-id"} string callId) returns MgvoMiddlewareResponse {
        return self.forward(GET_CANCELED_TRAININGS, callId);
    }

    isolated function forward(
            RequestType requestType,
            string callId,
            string? crypt\-key = null,
            map<anydata>? queryParams = null
    ) returns MgvoMiddlewareResponse {
        final http:Response result;
        if queryParams is null || crypt\-key is null {
            result = check self.mgvoClient->/(
                call_id = callId,
                reqtype = requestType,
                outmode = Json,
                version = 3.0
            );
        } else {
            var encrypted = encrypt(callId, crypt\-key, queryParams);
            if encrypted is error {
                return error httpscerr:BadRequestError(encrypted.toString(), encrypted);
            }
            result = check self.mgvoClient->/(
                call_id = callId,
                reqtype = requestType,
                outmode = Json,
                paras = encrypted,
                version = 3.0
            );
        }

        //io:println(result.getTextPayload());
        final var mimetype = mime:getMediaType(result.getContentType());

        if mimetype is mime:MediaType && mimetype.getBaseType() == "text/html" {
            final var payload = check result.getTextPayload();
            if payload.includes("Fehler: Sicherheitsverstoß!") {
                return error httpscerr:UnauthorizedError(string `Header "call-id" = "${callId}" is invalid`);
            }
            if payload.includes("Nicht erlaubt!") {
                return error httpscerr:UnauthorizedError(string `Header "call-id" = "${callId}" is invalid`);
            }
            if payload.includes("ERROR") {
                return error httpscerr:InternalServerErrorError(payload);
            }
            return error httpscerr:InternalServerErrorError(payload);
        }

        if (result.statusCode != 200) {
            panic error(string `${result.statusCode}, ${check result.getTextPayload()}`);
        }
        final var jsonpayload = check (result.getJsonPayload());
        final var response = jsonpayload.cloneWithType(MgvoResponse);
        if response is error {
            
            return error httpscerr:InternalServerErrorError(response.toString(), response);
        } else {
            return response;
        }
    }
}
