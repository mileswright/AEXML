/**
 *  https://github.com/tadija/AEXML
 *  Copyright (c) Marko Tadić 2014-2019
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

/// Simple wrapper around `Foundation.XMLParser`.
internal class AEXMLParser: NSObject, XMLParserDelegate {
    
    // MARK: - Properties
    
    let document: AEXMLDocument
    let data: Data
    
    var currentParent: AEXMLElement?
    var currentElement: AEXMLElement?
    var currentValue = String()
    
    var parseError: Error?
    
    private lazy var trimWhitespace: Bool = {
        let trim = self.document.options.parserSettings.shouldTrimWhitespace
        return trim
    }()
    
    // MARK: - Lifecycle
    
    init(document: AEXMLDocument, data: Data) {
        self.document = document
        self.data = data
        currentParent = document
        
        super.init()
    }
    
    // MARK: - API
    
    func parse() throws {
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        parser.shouldProcessNamespaces = document.options.parserSettings.shouldProcessNamespaces
        parser.shouldReportNamespacePrefixes = document.options.parserSettings.shouldReportNamespacePrefixes
        parser.shouldResolveExternalEntities = document.options.parserSettings.shouldResolveExternalEntities
        
        let success = parser.parse()
        
        if !success {
            guard let error = parseError else { throw AEXMLError.parsingFailed }
            throw error
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String]) {
        currentValue = String()
        currentElement = currentParent?.addChild(name: elementName, attributes: attributeDict)
        currentParent = currentElement
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let newValue = String(data: CDATABlock, encoding: .utf8) {
            currentValue += newValue
            if newValue == String() {
                currentElement?.value = nil
                currentElement?.isCDATA = nil
            }
            else {
                currentElement?.value = newValue
                currentElement?.isCDATA = true
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue.append(string)
        currentElement?.value = currentValue.isEmpty ? nil : currentValue
        currentElement?.isCDATA = currentValue.isEmpty ? nil : false
    }
    
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        if trimWhitespace {
            currentElement?.value = currentElement?.value?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        currentParent = currentParent?.parent
        currentElement = nil
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
    
}
