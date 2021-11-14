// ContentFeedPaymentDestination+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData


extension ContentFeedPaymentDestination {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContentFeedPaymentDestination> {
        return NSFetchRequest<ContentFeedPaymentDestination>(entityName: "ContentFeedPaymentDestination")
    }

    
    /// The public key address of the payment recipient
    @NSManaged
    public var address: String?
    
    
    /// The percentage of the suggested amount being sent to this destination
    @NSManaged
    public var split: Double
    
    
    @NSManaged
    public var type: String?
    
    
    @NSManaged
    public var customKey: String?
    
    
    @NSManaged
    public var customValue: String?
    
    
    @NSManaged
    public var feed: ContentFeed?
}

extension ContentFeedPaymentDestination : Identifiable {}



// MARK: -  Public Methods
extension ContentFeedPaymentDestination {
    
    public func legacyPodcastPaymentDestinationModel(
        fromLegacyPodcastFeed legacyPodcastFeed: PodcastFeed
    ) -> PodcastDestination {
        guard let managedObjectContext = managedObjectContext else {
            preconditionFailure()
        }
        
        let podcastDestinationModel = PodcastDestination(
            context: managedObjectContext
        )
        
        podcastDestinationModel.address = address
        podcastDestinationModel.split = split
        podcastDestinationModel.type = type
        podcastDestinationModel.feed = legacyPodcastFeed
        
        return podcastDestinationModel
    }
}


// MARK: - Coding Keys
extension ContentFeedPaymentDestination {
    
    enum CodingKeys: String, CodingKey {
        case address = "address"
        case split = "split"
        case type = "type"
        case customKey = "customKey"
        case customValue = "customValue"
    }
}
