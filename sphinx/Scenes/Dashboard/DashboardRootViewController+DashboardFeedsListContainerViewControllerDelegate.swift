import UIKit
import CoreData


extension DashboardRootViewController: DashboardFeedsListContainerViewControllerDelegate, NewsletterFeedContainerViewControllerDelegate {
    
    func viewController(_ viewController: UIViewController, didSelectFeedSearchResult feedId: String) {
        if let contentFeed = ContentFeed.getFeedWith(feedId: feedId) {
            if contentFeed.isPodcast {
                let podcastFeed = PodcastFeed.convertFrom(contentFeed: contentFeed)
                self.viewController(self, didSelectPodcastFeed: podcastFeed)
            } else if contentFeed.isVideo {
                self.viewController(self, didSelectVideoFeedWithID: contentFeed.objectID)
            } else if contentFeed.isNewsletter {
                self.viewController(self, didSelectNewsletterFeedWithID: contentFeed.objectID)
            }
        }
        
        actionsManager.saveFeedSearches()
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastEpisodeWithID podcastEpisodeID: NSManagedObjectID
    ) {
        guard
            let contentFeedItem = managedObjectContext.object(with: podcastEpisodeID) as? ContentFeedItem,
            contentFeedItem.contentFeed?.isPodcast == true
        else {
            return
        }
        
        guard let contentFeed = contentFeedItem.contentFeed else {
            return
        }
        
        let podcastFeed = PodcastFeed.convertFrom(contentFeed:  contentFeed)
        
        pausePlayingIfNeeded(podcast: podcastFeed, itemId: contentFeedItem.itemID)
        
        podcastFeed.currentEpisodeId = contentFeedItem.itemID
        
        podcastSmallPlayer.configureWith(
            podcastId: podcastFeed.feedID,
            delegate: self,
            andKey: PodcastDelegateKeys.DashboardSmallPlayerBar.rawValue
        )
        
        presentPodcastPlayerFor(podcastFeed)
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectPodcastFeed podcastFeed: PodcastFeed
    ) {
        guard let _ = podcastFeed.feedURLPath else {
            AlertHelper.showAlert(title: "Failed to find a URL for the feed.", message: "")
            return
        }
        
        feedsManager.restoreContentFeedStatusInBackgroundFor(feedId: podcastFeed.feedID)
        
        presentPodcastPlayerFor(podcastFeed)
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoFeedWithID videoFeedID: NSManagedObjectID
    ) {
        guard
            let contentFeed = managedObjectContext.object(with: videoFeedID) as? ContentFeed,
            contentFeed.isVideo
        else {
            preconditionFailure()
        }
        
        let videoFeed = VideoFeed.convertFrom(contentFeed: contentFeed)

        if let latestEpisode = videoFeed.videosArray.first {
            presentVideoPlayer(for: latestEpisode)
        } else {
            AlertHelper.showAlert(title: "Invalid channel or playlist", message: "No videos available")
        }
    }
    
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoEpisodeWithID videoEpisodeID: NSManagedObjectID
    ) {
        guard
            let contentFeedItem = managedObjectContext.object(with: videoEpisodeID) as? ContentFeedItem,
            contentFeedItem.contentFeed?.isVideo == true
        else {
            preconditionFailure()
        }
        
        if let contentFeed = contentFeedItem.contentFeed {
            
            let videoFeed = VideoFeed.convertFrom(contentFeed:  contentFeed)
            let videoEpisode = Video.convertFrom(contentFeedItem: contentFeedItem, videoFeed: videoFeed)
            
            presentVideoPlayer(for: videoEpisode)
        }
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterFeedWithID newsletterFeedID: NSManagedObjectID
    ) {
        guard
            let contentFeed = managedObjectContext.object(with: newsletterFeedID) as? ContentFeed,
            contentFeed.isNewsletter
        else {
            preconditionFailure()
        }
        
        let newsletterFeed = NewsletterFeed.convertFrom(contentFeed: contentFeed)
        presentNewsletterFeedVC(for: newsletterFeed)
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterItemWithID newsletterItemID: NSManagedObjectID
    ) {
        guard
            let contentFeedItem = managedObjectContext.object(with: newsletterItemID) as? ContentFeedItem,
            let contentFeed = contentFeedItem.contentFeed,
            contentFeed.isNewsletter
        else {
            preconditionFailure()
        }
        
        let newsletterFeed = NewsletterFeed.convertFrom(contentFeed: contentFeed)
        
        let newsletterFeedItem = NewsletterItem.convertFrom(
            contentFeedItem: contentFeedItem,
            newsletterFeed: newsletterFeed
        )
        
        presentItemWebView(for: newsletterFeedItem)
    }
    
    func viewController(
        _ viewController: UIViewController,
        didSelectRecommendationWithId recommendationId: String,
        from recommendations: [RecommendationResult]
    ) {
        presentRecommendationsPlayerVC(for: recommendations, and: recommendationId)
    }
}


extension DashboardRootViewController {
    
    func presentPodcastPlayerFor(
        _ podcast: PodcastFeed
    ) {
        if (podcast.isRecommendationsPodcast) {
            presentRecommendationsPlayerVC(for: podcast)
        } else {
            let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
                podcast: podcast,
                delegate: self,
                boostDelegate: self,
                fromDashboard: true
            )
            
            podcastFeedVC.modalPresentationStyle = .automatic
            
            navigationController?.present(podcastFeedVC, animated: true)
        }
    }
    
    
    private func presentVideoPlayer(
        for videoEpisode: Video
    ) {
        let viewController = VideoFeedEpisodePlayerContainerViewController
            .instantiate(
                videoPlayerEpisode: videoEpisode,
                dismissButtonStyle: .backArrow,
                delegate: self,
                boostDelegate: self
            )
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
    
    func presentItemWebView(
        for newsletterItem: NewsletterItem
    ) {
        let viewController = NewsletterItemDetailViewController
            .instantiate(
                newsletterItem: newsletterItem,
                boostDelegate: self
            )
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
    
    private func presentNewsletterFeedVC(
        for newsletterFeed: NewsletterFeed
    ) {
        let viewController = NewsletterFeedContainerViewController
            .instantiate(
                newsletterFeed: newsletterFeed,
                delegate: self
            )
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
    
    private func presentRecommendationsPlayerVC(
        for recommendations: [RecommendationResult],
        and recommendationId: String
    ) {
        let recommendationsHelper = RecommendationsHelper.sharedInstance
        
        let podcast = recommendationsHelper.getPodcastFor(
            recommendations: recommendations
        )
        
        pausePlayingIfNeeded(podcast: podcast, itemId: recommendationId)
        
        podcast.currentEpisodeId = recommendationId
        
        presentRecommendationsPlayerVC(for: podcast)
    }
    
    private func pausePlayingIfNeeded(
        podcast: PodcastFeed,
        itemId: String
    ) {
        if podcastPlayerController.isPlaying(podcastId: podcast.feedID) {
            if let episode = podcast.getCurrentEpisode(), let url = episode.getAudioUrl(), episode.itemID != itemId {
                podcastPlayerController.submitAction(
                    UserAction.Pause(
                        PodcastData(
                            podcast.chat?.id,
                            podcast.feedID,
                            episode.itemID,
                            url,
                            episode.currentTime,
                            episode.duration,
                            podcast.playerSpeed
                        )
                    )
                )
            }
        }
    }
    
    private func presentRecommendationsPlayerVC(
        for podcast: PodcastFeed
    ) {
        let viewController = RecommendationFeedPlayerContainerViewController
            .instantiate(podcast: podcast)
        
        viewController.modalPresentationStyle = .automatic
        
        navigationController?
            .present(viewController, animated: true)
    }
}
