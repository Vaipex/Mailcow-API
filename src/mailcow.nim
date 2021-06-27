import httpclient, uri, json, strformat

type
  Session* = ref object
    url*: Uri
    apikey*: string
    client*: HttpClient

proc setInfo*(domain: string, key: string): Session =

  var client = newHttpClient()
  client.headers = newHttpHeaders({
    "Content-Type": "application/json",
    "X-API-Key": key
  })

  return Session(url: domain.parseUri, apikey: key, client:client)

proc getDomains*(self: Session, id: string = "all"): JsonNode =
  let resp = self.client.getContent($(self.url / "api/v1/get/domain/" / id))
  return parseJson(resp)

proc createDomain*(self: Session, domain: string, description: string = "",
                  aliases: int = 400, mailboxes: int = 10, defquota: int = 3072,
                  maxquota: int = 10240, quota: int = 10240, active: int = 1,
                  rl_value: int = 10, rl_frame: string = "s", backupmx: int = 0,
                  relay_all_recipients: int = 0, restart_sogo: int = 0): JsonNode =
                
  let data = %*{
              "domain": domain,
              "description": description,
              "aliases": aliases,
              "mailboxes": mailboxes,
              "defquota": defquota,
              "maxquota": maxquota,
              "quota": quota,
              "active": active,
              "rl_value": rl_value,
              "rl_frame": rl_frame,
              "backupmx": backupmx,
              "relay_all_recipients": relay_all_recipients,
              "restart_sogo": relay_all_recipients
            }
  
  var resp = self.client.request($(self.url / "api/v1/add/domain"),
                                  httpMethod = HttpPost, body = $data)
  return parseJson(resp.body)

proc updateDomain*(self: Session, domain: string, description: string="",
                  aliases: string = "", mailboxes: string = "", defquota: string = "",
                  maxquota: string = "", quota: string = "", active: string = "",
                  backupmx: string = "", relay_all_recipients: string = "",
                  gal: string = "", relayhost: string = ""): JsonNode =

  let data = %*{
              "items": [
                domain
              ],
              "attr": {
                "description": description,
                "aliases": aliases,
                "mailboxes": mailboxes,
                "defquota": defquota,
                "maxquota": maxquota,
                "quota": quota,
                "active": active,
                "gal": gal,
                "relayhost": relayhost,
                "backupmx": backupmx,
                "relay_all_recipients": relay_all_recipients
              }
            }

  let resp = self.client.request($(self.url / "api/v1/edit/domain"), 
                                  httpMethod = HttpPost, body = $data)
  return parseJson(resp.body)

proc deleteDomain*(self:Session, domain: string): JsonNode =
  
  let data = fmt"""["{domain}"]"""
  let resp = self.client.request($(self.url / "api/v1/delete/domain"), 
                                  httpMethod = HttpPost, body = data)
  return parseJson(resp.body)

proc getDomainWhitelist*(self: Session, domain: string): JsonNode =

  let resp = self.client.getContent($(self.url / "api/v1/get/policy_wl_domain" / domain))
  return parseJson(resp)

proc getDomainBlacklist*(self: Session, domain: string): JsonNode =

  let resp = self.client.getContent($(self.url / "api/v1/get/policy_bl_domain" / domain))
  return parseJson(resp)

proc createDomainPolicy*(self: Session, domain: string, wl_bl: string, 
                        toblock: string): JsonNode =
  let data = %*{
              "domain": domain,
              "object_list": wl_bl,
              "object_from": toblock
            }
  let resp = self.client.request($(self.url / "api/v1/add/domain-policy"), 
                                  httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)
  
proc deleteDomainPolicy*(self: Session, domain: string): JsonNode =

  let data = fmt"""["{domain}"]"""

  let resp = self.client.request($(self.url / "api/v1/delete/domain-policy"), 
                                  httpMethod = HttpPost, body = data)
                              
  return parseJson(resp.body)

proc getMailboxes*(self: Session, id: string): JsonNode =

  let resp = self.client.getContent($(self.url / "api/v1/get/mailbox" / id))
  return parseJson(resp)

proc createMailbox*(self: Session, local_part: string, domain: string, name: string,
                    quota: string, password: string, active: bool, force_pw_update: bool,
                    tls_enforce_in: bool, tls_enforce_out: bool): JsonNode =
  
  let data = %*{
                "local_part": local_part,
                "domain": domain,
                "name": name,
                "quota": quota,
                "password": password,
                "password2": password,
                "active": active.int,
                "force_pw_update": force_pw_update.int,
                "tls_enforce_in": tls_enforce_in.int,
                "tls_enforce_out": tls_enforce_out.int,
                }

  let resp = self.client.request($(self.url / "api/v1/add/mailbox"), httpMethod = HttpPost,
                                body = $data)
    
  return parseJson(resp.body)

proc updateMailbox*(self: Session, mailbox: string, name: string = "",
                    quota: string = "", password: string = "", active: string = "",
                    force_pw_update: string = "", sogo: string = ""): JsonNode =

  let data = %*{
                "items": [
                  mailbox
                ],
                "attr": {
                   "attr": {
                    "name": name,
                    "quota": quota,
                    "password": password,
                    "password2": password,
                    "active": active,  
                    "force_pw_update": force_pw_update,
                    "sogo_access": sogo
                    }
                  }
              }

  let resp = self.client.request($(self.url / "api/v1/edit/mailbox"),
                                 httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc updateSpamScore*(self: Session, mailbox: string, score: string): JsonNode =

  let data = %*[
                {
                  "items": [
                    mailbox
                  ],
                  "attr": {
                    "spam_score": score
                  }
                }
              ]

  let resp = self.client.request($(self.url / "api/v1/edit/spam-score"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc deleteMailbox*(self: Session, mailbox: string): JsonNode =

  let data = %*[
                mailbox
               ]

  let resp = self.client.request($(self.url / "api/v1/delete/mailbox"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)  

proc setQuarantineNoti*(self: Session, mailbox: string, time: string): JsonNode =

  let data = %*{
                "items": [
                  mailbox
                ],
                "attr": {
                  "quarantine_notification": time
                }
              }

  let resp = self.client.request($(self.url / "api/v1/edit/quarantine_notification"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc getAliases*(self: Session, id: string): JsonNode =

  let resp = self.client.getContent($(self.url / "api/v1/get/alias" / id))

  return parseJson(resp)

proc createAlias*(self: Session, mailbox: string, goto: string, active: string): JsonNode =

  let data = %*{
                "address": mailbox,
                "goto": goto,
                "active": active
              }

  let resp = self.client.request($(self.url / "api/v1/add/alias"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc updateAlias*(self: Session, id: string, address: string = "", goto: string = "",
                  priv: string = "", pub: string = "", active: string = ""): JsonNode =
  
  let data = %*{
                "items": [
                  id
                ],
                "attr": {
                  "address": address,
                  "goto": goto,
                  "private_comment": priv,
                  "public_comment": pub,
                  "active": active
                }
              }

  let resp = self.client.request($(self.url / "api/v1/edit/alias"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc deleteAlias*(self: Session, id: string): JsonNode =
  
  let data = %*[
                id
              ]

  let resp = self.client.request($(self.url / "api/v1/delete/alias"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)
