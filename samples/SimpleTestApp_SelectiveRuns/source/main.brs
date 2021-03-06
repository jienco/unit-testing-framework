' ********** Copyright 2017 Roku Corp.  All Rights Reserved. **********

' Channel entry point
sub RunUserInterface(args)
    screen = CreateObject("roSGScreen")
    m.mainData = {
        scene: screen.CreateScene("Scene")
        screen: screen
    }
    screen.show()
    
    if args.RunTests = "true" and Type(TestRunner) = "Function" then
        Runner = TestRunner()

        Runner.SetFunctions([
            Main_Test1
            Main_Test2
            Main_Test3
            Main_RepeatedTest1
            Main_RepeatedTest2
            stringProvider
            Main_ParametrizedTest1
            Main_ParametrizedTest2
            Main_SkipTest
            NewTest__BeforeAllTests
            NewTest__AfterAllTests
            New_Test
        ])

        if args.IncludeFilter <> invalid
            Runner.SetIncludeFilter(args.IncludeFilter)
        end if

        if args.ExcludeFilter <> invalid
            Runner.SetExcludeFilter(args.ExcludeFilter)
        end if
        
        Runner.Logger.SetVerbosity(3)
        Runner.Logger.SetEcho(false)
        Runner.Logger.SetJUnit(false)

        Runner.Run()
    end if
end sub

' Part of channel specific logic, where you will work with some
' external resources, like REST API, etc. You may get raw data from feed, then
' parse it and return as a native BrightScript object(roAA, roArray, etc)
' with some proper Content Meta-Data structure.

' If you will have a complex parsing process with a lot of external resources,
' then it will be a good practice to move all logic to separate files.
function GetApiArray()
    url = CreateObject("roUrlTransfer")
    ' External resource
    url.SetUrl("http://api.delvenetworks.com/rest/organizations/59021fabe3b645968e382ac726cd6c7b/channels/1cfd09ab38e54f48be8498e0249f5c83/media.rss")
    rsp = url.GetToString()

    ' Utility function for XML parsing.
    ' Based on native Bright Script XML parser.
    responseXML = Utils_ParseXML(rsp)
    if responseXML <> invalid then
        responseXML = responseXML.GetChildElements()
        responseArray = responseXML.GetChildElements()
    end if

    ' The result will be roArray object.
    result = []

    if responseArray <> invalid and GetInterface(responseArray, "ifArray") <> invalid then
        ' Work with parsed XML and add to roArray some data.
        for each xmlItem in responseArray
            if xmlItem.getName() = "item"
                itemAA = xmlItem.GetChildElements()
                if itemAA <> invalid
                    item = {}
                    for each xmlItem in itemAA
                        if xmlItem.getName() = "media:content"
                            item.stream = { url: xmlItem.getAttributes().url }
                            item.url = xmlItem.getAttributes().url
                            item.streamFormat = "mp4"
                            mediaContent = xmlItem.GetChildElements()
                            for each mediaContentItem in mediaContent
                                if mediaContentItem.getName() = "media:thumbnail"
                                    item.HDPosterUrl = mediaContentItem.getattributes().url
                                    item.hdBackgroundImageUrl = mediaContentItem.getattributes().url
                                end if
                            end for
                        else
                            item[xmlItem.getName()] = xmlItem.getText()
                        end if
                    end for
                    result.push(item)
                end if
            end if
        end for
    end if
    return result
end function

' ----------------------------------------------------------------
' Prepends a prefix to every entry in Assoc Array

' @return An Assoc Array with new values if all values are Strings
' or invalid if one or more value is not String.
' ----------------------------------------------------------------
function AddPrefixToAAItems(AssocArray as Object) as Object
    prefix = "prefix__"

    for each key in AssocArray
        ' Get current item
        item = AssocArray[key]

        ' Check if current item is string
        if GetInterface(item, "ifString") <> invalid then
            ' Prepend a prefix to current item
            item = prefix + item
        else
            ' Return invalid if item is not string
            return invalid
        end if
    end for

    return AssocArray
end Function