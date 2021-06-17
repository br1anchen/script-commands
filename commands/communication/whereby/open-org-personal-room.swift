#!/usr/bin/swift

// @raycast.title Organization Personal room
// @raycast.author Brian
// @raycast.authorURL https://github.com/br1anchen
// @raycast.description Open personal room within organization in the default browser

// @raycast.icon images/whereby-logo.png
// @raycast.mode fullOutput
// @raycast.packageName Whereby
// @raycast.schemaVersion 1

import Cocoa

func makeRequestWithAuth(apiPath: String) -> URLRequest {
    let requestUrl = URL(string: "https://api.appearin.net\(apiPath)")!

    var request = URLRequest(url: requestUrl)

    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Basic <Your personal account auth token>", forHTTPHeaderField: "Authorization")

    return request
}


struct OrganizationModel: Codable {
    let organizationId: String
    let subdomain: String
    let type: String
}

struct OrganizationsResponseModel: Codable {
    let organizations: [OrganizationModel]
}

func parseOrganizationsJSON(data: Data) -> OrganizationsResponseModel? {

    var returnValue: OrganizationsResponseModel?
    do {
        returnValue = try JSONDecoder().decode(OrganizationsResponseModel.self, from: data)
    } catch {
        print("Error took place \(error.localizedDescription).")
        exit(1)
    }

    return returnValue
}

func getOrganizationInfo(completion: @escaping ((String, String)) -> ()) {
    let organizationsRequest = makeRequestWithAuth(apiPath: "/user/organizations")

    URLSession.shared.dataTask(with: organizationsRequest) { (data, response, error) in

        // Check if Error took place
        if let error = error {
            print("Error took place \(error)")
            exit(1)
        }

        // Convert HTTP Response Data to a simple String
        if let data = data, let dataString = String(data: data, encoding: .utf8) {
            print("Response data string:\n \(dataString)")
        }

        // Read HTTP Response Status code
        if let response = response as? HTTPURLResponse {
            print("Response HTTP Status code: \(response.statusCode)")
            if response.statusCode != 200 {
                exit(1)
            }
        }

        guard let data = data else { exit(1) }
        // Using parseJSON() function to convert data to Swift struct
        let organizationsResponse = parseOrganizationsJSON(data: data)

        let privateOrg = organizationsResponse?.organizations.first(where: { org in
            org.type == "private"
        })

        let orgId = privateOrg?.organizationId ?? "1"
        let subdomain = privateOrg?.subdomain ?? ""
        completion((orgId, subdomain))

    }.resume()
}

struct RoleModel: Codable {
    let mutedUntil: Date?
    let roleName: String
    let roomName: String
    let numberOfUnreadMessages: Int
}

struct RolesResponseModel: Codable {
    let roles: [RoleModel]
}

func parseRolesJSON(data: Data) -> RolesResponseModel? {

    var returnValue: RolesResponseModel?
    do {
        returnValue = try JSONDecoder().decode(RolesResponseModel.self, from: data)
    } catch {
        print("Error took place \(error.localizedDescription).")
        exit(1)
    }

    return returnValue
}

func getOrgPersonalRoomName (orgId: String, completion: @escaping ((String)) -> ()) {
    let rolesApiPath = "/organizations/\(orgId)/user/roles"
    let rolesRequest = makeRequestWithAuth(apiPath: rolesApiPath)

    URLSession.shared.dataTask(with: rolesRequest) { (data, response, error) in

        // Check if Error took place
        if let error = error {
            print("Error took place \(error)")
            exit(1)
        }

        // Convert HTTP Response Data to a simple String
        if let data = data, let dataString = String(data: data, encoding: .utf8) {
            print("Response data string:\n \(dataString)")
        }

        // Read HTTP Response Status code
        if let response = response as? HTTPURLResponse {
            print("Response HTTP Status code: \(response.statusCode)")
            if response.statusCode != 200 {
                exit(1)
            }
        }

        guard let data = data else { exit(1) }
        // Using parseJSON() function to convert data to Swift struct
        let rolesResponse = parseRolesJSON(data: data)

        guard let ownerRole = rolesResponse?.roles.first(where: { r in
            r.roleName == "owner"
        }) else { exit(1) }

        completion(ownerRole.roomName)

    }.resume()
}

getOrganizationInfo { (orgId, subdomain) in
    if subdomain != "" {
        getOrgPersonalRoomName(orgId: orgId) { (roomName) in
            let personalRoomURLStr = "https://\(subdomain).whereby.com\(roomName)"
            print("OrgPersonalRoomURL: \(personalRoomURLStr)")
            let personalRoomURL = URL(string: personalRoomURLStr)!
            NSWorkspace.shared.open(personalRoomURL)
            exit(0)
        }
    }else {
        print("Does not have organization account")
        exit(1)
    }
}

RunLoop.main.run()
