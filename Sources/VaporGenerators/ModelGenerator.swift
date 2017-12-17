import Foundation
import Console

internal final class ModelGenerator: AbstractGenerator {
    
    private enum ReplacementKeys: String {
        case className = "_CLASS_NAME_"
        case variableName = "_IVAR_NAME_"
        case dbTableName = "_DB_TABLE_NAME_"
        case ivarsDefinition = "_IVARS_DEFINITION_"
        case ivarsInitializer = "_IVARS_INITIALIZER_"
        case ivarsNodeConversion = "_IVARS_DICTIONARY_PAIRS_"
        case dbTableRowsDefinition = "_TABLE_ROWS_DEFINITION_"
        case keysDefinition = "_KEYS_DEFINITION_"
        case toJSON = "_CLASS_TO_JSON_"
        case jsonInit = "_CLASS_JSON_INIT_"
        case fluentInitalizer = "_FLUENT_INITIALIZER_"
        case fluentSerialize = "_FLUENT_SERIALIZE_"
        case defaultInitParams = "_DEFAULT_INIT_PARAMS_"
        case defaultInitImplementation = "_DEFAULT_INIT_IMPLEMENTATION_"
    }
    
    private enum Directories: String {
        case models = "Sources/App/Models/"
        case modelTests = "Tests/AppTests/Models/"
    }
    
    private enum Templates: String {
        case model = "Model"
    }
    
    override internal var signature: [Argument] {
        return super.signature + [
            Value(name: "properties", help: ["An optional list of properties in the format variable:type (e.g. firstName:string lastname:string)"]),
        ]
    }
    
    override func performGeneration(arguments: [String]) throws {
        guard let name = arguments.first else {
            throw ConsoleError.argumentNotFound
        }
        let ivars = arguments.values.filter { return $0.contains(":") }
        console.print("Model '\(name)' with ivars \(ivars)")
        try generateModelClass(named: name, ivars: ivars)
        try generateModelTests(className: name)
    }
    
    func generateModelClass(named name: String, ivars: [String]) throws {
        let filePath = "\(Directories.models.rawValue)\(name.capitalized).swift"
        try copyTemplate(atPath: pathForTemplate(named: Templates.model.rawValue), toPath: filePath) { (contents) in
            func spacing(_ x: Int) -> String {
                guard x > 0 else { return "" }
                var result = ""
                for _ in 0 ..< x {
                    result += " "
                }
                return result
            }
            
            var newContents = contents
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.className.rawValue,
                                                           with: name.capitalized)
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.variableName.rawValue,
                                                           with: name.lowercased())
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.dbTableName.rawValue,
                                                           with: name.pluralized)
            
            var ivarDefinitions = ""
            var ivarInitializers = ""
            var ivarDictionaryPairs = ""
            var tableRowsDefinition = ""
            var keysDefinition = ""
            var toJSON = ""
            var jsonInit = ""
            var fluentInitializer = ""
            var fluentSerialize = ""
            var initParamsDefinition = ""
            var initImplementation = ""
            var isFirstIvar = true
            for ivar in ivars {
                let components = ivar.components(separatedBy: ":")
                let ivarName = components.first!
                let ivarType = components.last!
                let normalizedIvar = ivarName.snakeCased
                ivarDefinitions += "\(spacing(4))var \(ivarName): \(ivarType.capitalized)\n"
                ivarInitializers += "\(spacing(8))\(ivarName) = try node.extract(\"\(normalizedIvar)\")\n"
                ivarDictionaryPairs += "\(spacing(12))\"\(normalizedIvar)\": \(ivarName),\n"
                tableRowsDefinition += "\(spacing(12))$0.\(ivarType.lowercased())(\"\(normalizedIvar)\")\n"
                
                keysDefinition += "\(spacing(8))static let \(ivarName) = \"\(normalizedIvar)\"\n"
                
                toJSON += "\(spacing(8))try json.set(\(name.capitalized).Keys.\(ivarName), \(ivarName))\n"
                
                if !isFirstIvar {
                    jsonInit += ",\n"
                }
                
                jsonInit += "\(spacing(12))\(ivarName): try json.get(\(name.capitalized).Keys.\(ivarName))"
                
                fluentInitializer += "\(spacing(8))\(ivarName) = try row.get(\(name.capitalized).Keys.\(ivarName))\n"
                
                fluentSerialize += "\(spacing(8))try row.set(\(name.capitalized).Keys.\(ivarName), \(ivarName))\n"
                
                if !isFirstIvar {
                    initParamsDefinition += ", "
                }
                
                initParamsDefinition += "\(ivarName):\(ivarType.capitalized)"
                
                initImplementation += "\(spacing(8))self.\(ivarName) = \(ivarName)\n"
                
                isFirstIvar = false
            }
            
            ivarDefinitions = ivarDefinitions.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            ivarInitializers = ivarInitializers.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            ivarDictionaryPairs = ivarDictionaryPairs.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            tableRowsDefinition = tableRowsDefinition.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            keysDefinition = keysDefinition.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            toJSON = toJSON.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            jsonInit = jsonInit.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            fluentInitializer = fluentInitializer.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            fluentSerialize = fluentSerialize.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            initImplementation = initImplementation.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.ivarsDefinition.rawValue,
                                                           with: ivarDefinitions)
            //            newContents = newContents.replacingOccurrences(of: ReplacementKeys.ivarsInitializer.rawValue,
            //                                                           with: ivarInitializers)
            //            newContents = newContents.replacingOccurrences(of: ReplacementKeys.ivarsNodeConversion.rawValue,
            //                                                           with: ivarDictionaryPairs)
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.dbTableRowsDefinition.rawValue,
                                                           with: tableRowsDefinition)
            
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.keysDefinition.rawValue,
                                                           with: keysDefinition)
            
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.toJSON.rawValue,
                                                           with: toJSON)
            
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.jsonInit.rawValue,
                                                           with: jsonInit)
            
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.fluentInitalizer.rawValue,
                                                           with: fluentInitializer)
            
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.fluentSerialize.rawValue,
                                                           with: fluentSerialize)
            
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.defaultInitParams.rawValue,
                                                           with: initParamsDefinition)
            
            newContents = newContents.replacingOccurrences(of: ReplacementKeys.defaultInitImplementation.rawValue,
                                                           with: initImplementation)
            
            return newContents
        }
    }
    
    func generateModelTests(className: String) throws {
        let testsGenerator = TestsGenerator(console: console)
        try testsGenerator.generate(arguments: [className, Directories.modelTests.rawValue])
    }
    
}

extension String {
    
    public var decapitalized: String {
        guard !isEmpty else { return self }
        if self[startIndex] == self.uppercased()[startIndex] {
            return replacingCharacters(in: startIndex..<index(after: startIndex), with: String(self[startIndex]).lowercased())
        }
        return self
    }
    
    public var snakeCased: String {
        func snakeCaseCapitals(_ input: String) -> String {
            var result = input
            while let range = result.rangeOfCharacter(from: .uppercaseLetters) {
                result = replacingCharacters(in: range, with: "_\(substring(with: range).lowercased())")
            }
            return result
        }
        return components(separatedBy: CharacterSet.alphanumerics.inverted).filter({ !$0.isEmpty })
            .map({ snakeCaseCapitals($0.decapitalized) })
            .joined(separator: "_")
            .lowercased()
    }
    
}
