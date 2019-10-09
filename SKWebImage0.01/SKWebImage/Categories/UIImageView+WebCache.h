//
//  UIImageView+WebCache.h
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/22.
//  Copyright © 2019 侯森魁. All rights reserved.
//


#import "SKWebImageCompat.h"
#import "SKImageManager.h"
NS_ASSUME_NONNULL_BEGIN
/**
 * Integrates SKWebImage async downloading and caching of remote images with UIImageView.
 *
 * Usage with a UITableViewCell sub-class:
 *
 *     #import <SKWebImage/UIImageView+WebCache.h>
 *
 *     ...
 *
 *     - (UITableViewCell *)tableView:(UITableView *)tableView
 *              cellForRowAtIndexPath:(NSIndexPath *)indexPath
 *     {
 *         static NSString *MyIdentifier = @"MyIdentifier";
 *
 *         UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
 *
 *         if (cell == nil)
 *         {
 *             cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
 *                                            reuseIdentifier:MyIdentifier] autorelease];
 *         }
 *
 *         // Here we use the provided setImageWithURL: method to load the web image
 *         // Ensure you use a placeholder image otherwise cells will be initialized with no image
 *         [cell.imageView setImageWithURL:[NSURL URLWithString:@"http://example.com/image.jpg"]
 *                        placeholderImage:[UIImage imageNamed:@"placeholder"]];
 *
 *         cell.textLabel.text = @"My Text";
 *         return cell;
 *     }
 *
 */

@interface UIImageView (WebCache)

/**
 * Set the imageView `image` with an `url`.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url that the image is found.
 * @see setImageWithURL:placeholderImage:
 */

- (void)setImageWithURL:(NSURL *)url;

/**
 * Set the imageView `image` with an `url` and a placeholder.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url that the `image` is found.
 * @param placeholder A `image` that will be visible while loading the final image.
 * @see setImageWithURL:placeholderImage:options:
 */

- (void)setImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder;
/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url that the `image` is found.
 * @param placeholder A `image` that will be visible while loading the final image.
 * @param options A list of `SKWebImageOptions` for current `imageView`. Available options are `SKWebImageRetryFailed`, `SKWebImageLowPriority` and `SKWebImageCacheMemoryOnly`.
 */

- (void)setImageWithURL:(NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SKWebImageOptions)options;

- (void)setImageWithURL:(NSURL *)url completed:(SKWebImageCompletedBlock )completedBlock;

/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options The options to use when downloading the image. @see SKWebImageOptions for the possible values.
 * @param completedBlock A block called when operation has been completed. This block as no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 */
- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(nullable UIImage *)placeholder
                options:(SKWebImageOptions)options
              completed:(SKWebImageCompletedBlock)completedBlock;
/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options The options to use when downloading the image. @see SKWebImageOptions for the possible values.
 * @param progressBlock A block called while image is downloading
 * @param completedBlock A block called when operation has been completed. This block as no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 */
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SKWebImageOptions)options progress:(SKWebImageDownloaderProgressBlock)progressBlock completed:(SKWebImageCompletedBlock)completedBlock;


/**
 * Cancel the current download
 */
- (void)cancelCurrentImageLoad;
@end

NS_ASSUME_NONNULL_END
