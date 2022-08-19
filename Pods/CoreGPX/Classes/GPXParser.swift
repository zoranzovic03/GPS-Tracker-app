//
//  GPXParser.swift
//  GPXKit
//
//  Created by Vincent on 2/11/18.
//  

import Foundation
/**
 An event-driven parser (SAX parser), that specifically parses GPX v1.1 files only.
 
 This parser is already setted up, hence, does not require any handling, and will parse files directly as objects.
 To get the parsed data from a GPX file, simply initialize the parser, and get the `GPXRoot` from `parsedData()`.
 */
open class GPXParser: NSObject {
    
    private let parser: XMLParser
    
    // MARK:- Initializers
    
    /// for parsing with `Data` type
    ///
    /// - Parameters:
    ///     - data: The input must be `Data` object containing GPX markup data, and should not be `nil`
    ///
    public init(withData data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
    }
    
    /// for parsing with `InputStream` type
    ///
    /// - Parameters:
    ///     - stream: The input must be a input stream allowing GPX markup data to be parsed synchronously
    ///
    public init(withStream stream: InputStream) {
        self.parser = XMLParser(stream: stream)
        super.init()
    }
    
    /// for parsing with `URL` type
    ///
    /// - Parameters:
    ///     - url: The input must be a `URL`, which should point to a GPX file located at the URL given
    ///
    public init?(withURL url: URL) {
        guard let urlParser = XMLParser(contentsOf: url) else { return nil }
        self.parser = urlParser
        super.init()
    }
    
    /// for parsing with a string that contains full GPX markup
    ///
    /// - Parameters:
    ///     - string: The input `String` must contain full GPX markup, which is typically contained in a `.GPX` file
    ///
    public convenience init?(withRawString string: String?) {
        if let string = string {
            if let data = string.data(using: .utf8) {
                self.init(withData: data)
            }
            else { return nil }
        }
        else { return nil }
    }
    
    /// for parsing with a path to a GPX file
    ///
    /// - Parameters:
    ///     - path: The input path, with type `String`, must contain a path that points to a GPX file used to facilitate parsing.
    ///
    public convenience init?(withPath path: String) {
        guard let url = URL(string: path) else { return nil }
        self.init(withURL: url)
    }
    
    // MARK:- GPX Parsing
    
    private var element = String()
    
    private var root = GPXRoot()
    
    // MARK:- Main element types or components
    private var waypoints = [GPXWaypoint]()
    
    private var routes = [GPXRoute]()
    private var routepoints = [GPXRoutePoint]()
    
    private var tracks = [GPXTrack]()
    private var tracksegements = [GPXTrackSegment]()
    private var trackpoints = [GPXTrackPoint]()
    
    // MARK:- Main singular element types.
    private var metadata: GPXMetadata?
    private var extensions: GPXExtensions?
    
    // MARK:- Dictionary of element for parsing use.
    private var waypointDict = [String : String]()
    private var trackDict = [String : String]()
    private var tracksegDict = [String : String]()
    private var trackpointDict = [String : String]()
    private var routeDict = [String : String]()
    private var routepointDict = [String : String]()
    
    private var linkDict = [String : String]()
    
    // Metadata types
    private var metadataDict = [String : String]()
    private var boundsDict = [String : String]()
    private var authorDict = [String : String]()
    private var emailDict = [String : String]()
    private var copyrightDict = [String : String]()
    
    // for GPX Header
    // private var rootDict = [String : String]()
    
    // MARK:- GPX v1.1 XML Schema tag types check
    private var isWaypoint = false
    private var isMetadata = false
    private var isRoute = false
    private var isRoutePoint = false
    private var isTrack = false
    private var isTrackSegment = false
    private var isTrackPoint = false
    private var isExtensions = false
  
    private var isLink = false
    private var elementHasLink = false
    
    // for metadata
    private var isBounds = false
    private var elementHasBounds = false
    private var isAuthor = false
    private var elementHasAuthor = false
    private var isEmail = false
    private var elementHasEmail = false
    private var isCopyright = false
    private var elementHasCopyright = false
    
    private var extensionIndex = 0
    
    // MARK:- Export parsed data
    
    public func parsedData() -> GPXRoot {
        self.parser.delegate = self
        self.parser.parse()
        
        root.metadata = metadata
        root.add(waypoints: waypoints)
        root.add(routes: routes)
        root.add(tracks: tracks)
        return root
    }
}

// MARK:- XMLParser Delegate

/**
 XML/GPX parser delegate implementation.
 
 This extension handles all the data, as the parser works its way through the XML elements.
 */
extension GPXParser: XMLParserDelegate {
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        element = elementName
        
        switch elementName {
        //case "gpx":
            //rootDict = attributeDict
        case "wpt":
            isWaypoint = true
            waypointDict = attributeDict
        case "trk":
            isTrack = true
        case "trkseg":
            isTrackSegment = true
        case "trkpt":
            isTrackPoint = true
            trackpointDict = attributeDict
        case "rte":
            isRoute = true
        case "rtept":
            isRoutePoint = true
            routepointDict = attributeDict
        case "metadata":
            isMetadata = true
        case "extensions":
            isExtensions = true
        case "link":
            isLink = true
            linkDict = attributeDict
            
        // for metadata
        case "bounds":
            isBounds = true
            boundsDict = attributeDict
        case "author":
            isAuthor = true
        case "email":
            isEmail = true
        case "copyright":
            isCopyright = true
            copyrightDict = attributeDict
        default:
            if isExtensions {
                parserFoundExtensionCode()
            }
            break
        }
        
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let foundString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if foundString.isEmpty == false {
            
            if isExtensions {
                element = "\(element), \(extensionIndex)"
            }
            if isWaypoint {
                if isLink {
                    linkDict[element] = foundString
                }
                else {
                    waypointDict[element] = foundString
                }
            }
            if isTrack && !isTrackPoint && !isTrackSegment {
                if isLink {
                    linkDict[element] = foundString
                }
                trackDict[element] = foundString
            }
            if isTrackPoint {
                if isLink {
                    linkDict[element] = foundString
                }
                else {
                    trackpointDict[element] = foundString
                }
            }
            if isRoute && !isRoutePoint {
                if isLink {
                    linkDict[element] = foundString
                }
                routeDict[element] = foundString
            }
            if isRoutePoint {
                if isLink {
                    linkDict[element] = foundString
                }
                else {
                    routepointDict[element] = foundString
                }
            }
            if isMetadata {
                if isLink && !isAuthor {
                    linkDict[element] = foundString
                }
                if isBounds {
                    // do nothing
                }
                if isAuthor {
                    if isLink {
                        linkDict[element] = foundString
                    }
                    else {
                        if isEmail {
                            emailDict[element] = foundString
                        }
                        authorDict[element] = foundString
                    }
                }
                if isCopyright {
                    copyrightDict[element] = foundString
                }
                else {
                    metadataDict[element] = foundString
                }
            }
            /*
            if isExtensions && !isMetadata && !isBounds && !isAuthor && !isCopyright && !isEmail && !isRoute && !isRoutePoint && !isTrack && !isTrackPoint && !isTrackSegment && !isWaypoint {
                rootDict[element] = foundString
            }
            */
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "metadata":
            self.metadata = GPXMetadata(dictionary: &metadataDict)
            if elementHasLink && !elementHasAuthor {
                self.metadata?.link = GPXLink(dictionary: linkDict)
                
                // clear values
                linkDict.removeAll()
                elementHasLink = false
            }
            if elementHasBounds {
                self.metadata?.bounds = GPXBounds(dictionary: boundsDict)
                
                // clear values
                boundsDict.removeAll()
                elementHasBounds = false
            }
            if elementHasAuthor {
                let author = GPXAuthor(dictionary: authorDict)
                if elementHasLink {
                    author.link = GPXLink(dictionary: linkDict)
                    
                    // clear values
                    linkDict.removeAll()
                    elementHasLink = false
                }
                if elementHasEmail {
                    author.email = GPXEmail(dictionary: emailDict)
                    
                    // clear values
                    emailDict.removeAll()
                    elementHasEmail = false
                }
                self.metadata?.author = author
                
                // clear values
                authorDict.removeAll()
                elementHasAuthor = false
            }
            if elementHasCopyright {
                self.metadata?.copyright = GPXCopyright(dictionary: copyrightDict)
                
                // clear values
                copyrightDict.removeAll()
                elementHasCopyright = false
            }
            
            // clear values
            isMetadata = false
            metadataDict.removeAll()
            
        case "trkpt":
            let tempTrackPoint = GPXTrackPoint(dictionary: &trackpointDict)
            if elementHasLink {
                tempTrackPoint.link = GPXLink(dictionary: linkDict)
                linkDict.removeAll()
                elementHasLink = false
            }
            self.trackpoints.append(tempTrackPoint)
            
            // clear values
            isTrackPoint = false
            extensionIndex = 0
            trackpointDict.removeAll()
            
        case "wpt":
            let tempWaypoint = GPXWaypoint(dictionary: &waypointDict)
            if elementHasLink {
                tempWaypoint.link = GPXLink(dictionary: linkDict)
                linkDict.removeAll()
                elementHasLink = false
            }
            self.waypoints.append(tempWaypoint)
            
            // clear values
            isWaypoint = false
            extensionIndex = 0
            waypointDict.removeAll()
            
        case "rte":
            let tempRoute = GPXRoute(dictionary: &routeDict)
            tempRoute.add(routepoints: self.routepoints)
            if elementHasLink {
                tempRoute.link = GPXLink(dictionary: linkDict)
                linkDict.removeAll()
                elementHasLink = false
            }
            self.routes.append(tempRoute)
            
            // clear values
            isRoute = false
            extensionIndex = 0
            self.routepoints.removeAll()
            
        case "rtept":
            let tempRoutePoint = GPXRoutePoint(dictionary: &routepointDict)
            if elementHasLink {
                tempRoutePoint.link = GPXLink(dictionary: linkDict)
                linkDict.removeAll()
                elementHasLink = false
            }
            self.routepoints.append(tempRoutePoint)
            
            // clear values
            isRoutePoint = false
            extensionIndex = 0
            self.routepointDict.removeAll()
            
        case "trk":
            let tempTrack = GPXTrack(dictionary: &trackDict)
            tempTrack.add(trackSegments: self.tracksegements)
            if elementHasLink {
                tempTrack.link = GPXLink(dictionary: linkDict)
                linkDict.removeAll()
                elementHasLink = false
            }
            self.tracks.append(tempTrack)
            
            //clear values
            isTrack = false
            extensionIndex = 0
            self.trackDict.removeAll()
            self.tracksegements.removeAll()
            
        case "trkseg":
            let tempTrackSegment = GPXTrackSegment()
            tempTrackSegment.add(trackpoints: self.trackpoints)
            self.tracksegements.append(tempTrackSegment)
            
            // clear values
            isTrackSegment = false
            extensionIndex = 0
            self.trackpoints.removeAll()
            
        case "extensions":
            self.extensions = GPXExtensions()
            
            // clear values
            extensionIndex = 0
            isExtensions = false
            
        case "link":
            elementHasLink = true
            
            // clear values
            isLink = false
            
        case "bounds":
            elementHasBounds = true
            
            // clear values
            isBounds = false
            
        case "author":
            elementHasAuthor = true
            
            // clear values
            isAuthor = false
            
        case "email":
            elementHasEmail = true
            
            // clear values
            isEmail = false
            
        case "copyright":
            elementHasCopyright = true
            
            // clear values
            isCopyright = false
            /*
        case "gpx":
            self.root = GPXRoot(dictionary: &rootDict)
            rootDict.removeAll()
 */
        default:
            let key = "\(elementName), \(extensionIndex)"
            let def = "internalParsingIndex \(extensionIndex)"
            if trackpointDict[key] == def || routepointDict[key] == def || waypointDict[key] == def || tracksegDict[key] == def || trackDict[key] == def || routeDict[key] == def || linkDict[key] == def || metadataDict[key] == def || boundsDict[key] == def || authorDict[key] == def || emailDict[key] == def || copyrightDict[key] == def {
                extensionIndex += 1
            }
            else {
                break
            }
        }
    }

}

extension GPXParser {
    
    /// Invoked when parser finds non standard data, which will be treated as extensions data.
    func parserFoundExtensionCode() {
        
        let key = "\(element), \(extensionIndex)"
        let indexValue = "internalParsingIndex \(extensionIndex)"
        
        
        if isTrackPoint {
            trackpointDict[key] = indexValue
        }
        else if isRoutePoint {
            routepointDict[key] = indexValue
        }
        else if isWaypoint {
            waypointDict[key] = indexValue
        }
        else if isTrack {
            trackDict[key] = indexValue
        }
        else if isTrackSegment {
            tracksegDict[key] = indexValue
        }
        else if isAuthor {
            authorDict[key] = indexValue
        }
        else if isBounds {
            boundsDict[key] = indexValue
        }
        else if isCopyright {
            copyrightDict[key] = indexValue
        }
        else if isEmail {
            emailDict[key] = indexValue
        }
        else if isLink {
            linkDict[key] = indexValue
        }
        else if isRoute {
            routeDict[key] = indexValue
        }
            /* DOES NOT WORK
        else { // for extension directly on GPXRoot
            rootDict[key] = indexValue
        }
 */
    }
}
