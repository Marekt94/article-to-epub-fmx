object DataModule1: TDataModule1
  Height = 379
  Width = 456
  PixelsPerInch = 120
  object RESTClient1: TRESTClient
    Accept = 'application/json'
    AcceptCharset = 'utf-8, *;q=0.8'
    AcceptEncoding = 'gzip, deflate, br'
    BaseURL = 'http://192.168.0.42:8080'
    ContentType = 'application/x-www-form-urlencoded'
    Params = <
      item
        Kind = pkHTTPHEADER
        Name = 'Authorization'
        Options = [poDoNotEncode]
        Value = 'API-key wrong_api'
      end>
    SynchronizedEvents = False
    Left = 32
    Top = 312
  end
  object RRHealth: TRESTRequest
    Client = RESTClient1
    Params = <>
    Resource = 'health'
    Response = HelthResp
    SynchronizedEvents = False
    Left = 288
    Top = 32
  end
  object RRFetchURLWithEpubInResp: TRESTRequest
    AssignedValues = [rvAccept]
    Accept = 'application/json'
    Client = RESTClient1
    Method = rmPOST
    Params = <
      item
        Kind = pkREQUESTBODY
        Value = 
          '{"url": "https://fs.blog/mental-models/?utm_source=unknownews","' +
          'email": []}'
        ContentTypeStr = 'application/json'
      end>
    Resource = 'api/fetch-url'
    Response = FetchURLWithEpubInResp
    SynchronizedEvents = False
    Left = 288
    Top = 120
  end
  object FetchURLWithEpubInResp: TRESTResponse
    Left = 32
    Top = 16
  end
  object RRFetchURLWithSend: TRESTRequest
    AssignedValues = [rvConnectTimeout, rvReadTimeout]
    Client = RESTClient1
    Method = rmPOST
    Params = <
      item
        Kind = pkREQUESTBODY
        Name = 'Body'
        Options = [poDoNotEncode]
        Value = 
          '{"url": "https://fs.blog/mental-models/?utm_source=unknownews","' +
          'email": ["marekt94@gmail.com"]}'
      end
      item
        Kind = pkHTTPHEADER
        Name = 'Authorization'
        Options = [poDoNotEncode]
        Value = 'API-Key api_key_test'
      end>
    Resource = 'api/fetch-url'
    Response = FetchURLWithSendResp
    SynchronizedEvents = False
    Left = 288
    Top = 216
  end
  object FetchURLWithSendResp: TRESTResponse
    ContentType = 'application/json'
    Left = 32
    Top = 104
  end
  object HelthResp: TRESTResponse
    Left = 32
    Top = 184
  end
  object RRConvertHtml: TRESTRequest
    Client = RESTClient1
    Method = rmPOST
    Params = <>
    Resource = 'api/convert-html'
    Response = ConvertHtmlResp
    SynchronizedEvents = False
    Left = 288
    Top = 296
  end
  object ConvertHtmlResp: TRESTResponse
    ContentType = 'application/json'
    Left = 32
    Top = 264
  end
end
