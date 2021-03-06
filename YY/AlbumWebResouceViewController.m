//
//  AlbumWebResouceViewController.m
//  YY
//
//  Created by Pierr Chen on 12-7-15.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import "AlbumWebResouceViewController.h"

@interface AlbumWebResouceViewController ()

@end

@implementation AlbumWebResouceViewController
@synthesize webView;
@synthesize browserForwardButton;
@synthesize browserBackButton;
@synthesize urlString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.webView.delegate = self;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setBrowserBackButton:nil];
    [self setBrowserForwardButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UIWebViewDelegate


- (void)webViewDidStartLoad:(UIWebView *)webView
{
    // starting the load, show the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // finished loading, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
     
    [self setWebviewNavigationButtonStatu];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // load error, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // report the error inside the webview
    NSString* errorString = [NSString stringWithFormat:
                             @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
                             error.localizedDescription];
    [self.webView loadHTMLString:errorString baseURL:nil];
}


- (void)setWebviewNavigationButtonStatu
{
    if ([self.webView canGoBack]) {
        self.browserBackButton.enabled = YES; 
    }else {
        self.browserBackButton.enabled = NO;
    }
    
    
    if ([self.webView canGoForward]) {
        self.browserForwardButton.enabled = YES; 
    }else {
        self.browserForwardButton.enabled = NO;
    }
    
    
    
}

- (IBAction)navigateBack {
    
    [self.webView goBack];
    
}

- (IBAction)navigateForward {
    [self.webView goForward];
}
@end
