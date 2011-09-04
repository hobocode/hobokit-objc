//  Copyright (c) 2011 HoboCode
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "HKStoreController.h"

#import "HKStorePurchase.h"
#import "HKStoreObserver.h"

static HKStoreController *gHKStoreController = nil;

@interface HKStoreController (Private)

- (void)completeTransaction:(SKPaymentTransaction *)transaction;
- (void)restoreTransaction:(SKPaymentTransaction *)transaction;
- (void)failedTransaction:(SKPaymentTransaction *)transaction;

@end

@implementation HKStoreController

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized ( self )
    {
        if ( gHKStoreController == nil )
        {
            gHKStoreController = [super allocWithZone:zone];
            
            return gHKStoreController;
        }
    }
    
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;
}

- (oneway void)release
{
}

- (id)autorelease
{
    return self;
}

- (id)init
{
    if ( self = [super init] )
    {
        _lookups = [[NSMutableDictionary alloc] init];
        _purchases = [[NSMutableDictionary alloc] init];
        _requests = [[NSMutableSet alloc] init];
        _observers = [[NSMutableSet alloc] init];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    
    return self;
}

- (void)dealloc
{
#ifdef HK_DEBUG_DEALLOC
    NSLog(@"Dealloc: %@", self);
#endif
    [_lookups release]; _lookups = nil;
    [_purchases release]; _purchases = nil;
    [_requests release]; _requests = nil;
    [_observers release]; _observers = nil;
    [super dealloc];
}

#pragma mark Public API

+ (HKStoreController *)defaultController
{
    @synchronized (self)
    {
        if ( gHKStoreController == nil )
        {
            [[self alloc] init];
        }
    }
    
    return gHKStoreController;
}

- (void)addStoreObserver:(id <HKStoreObserver>)storeObserver
{
    [_observers addObject:storeObserver];
}

- (void)removeStoreObserver:(id <HKStoreObserver>)storeObserver
{
    [_observers removeObject:storeObserver];
}

- (void)lookup:(NSSet *)purchases
{
    SKProductsRequest   *request;
    NSMutableSet        *identifiers = [NSMutableSet setWithCapacity:[purchases count]];
    NSString            *identifier;
    
    for ( id <HKStorePurchase> purchase in purchases )
    {
        identifier = [purchase identifier];
        
        if ( identifier )
        {
            if ( [_lookups objectForKey:identifier] == nil )
            {
                [_lookups setObject:purchase forKey:identifier];
                
                [identifiers addObject:identifier];
            }
        }
    }
    
    request = [[[SKProductsRequest alloc] initWithProductIdentifiers:identifiers] autorelease];
    request.delegate = self;
    
    [_requests addObject:request];
    
    [request start];
}

- (void)purchase:(NSSet *)purchases
{
    SKPayment           *payment;
    NSMutableSet        *identifiers = [NSMutableSet setWithCapacity:[purchases count]];
    NSString            *identifier;
    
    for ( id <HKStorePurchase> purchase in purchases )
    {
        identifier = [purchase identifier];
        
        if ( identifier )
        {
            if ( [_purchases objectForKey:identifier] == nil )
            {
                [_purchases setObject:purchase forKey:identifier];
                
                [identifiers addObject:identifier];
            }
        }
    }
    
    for ( identifier in identifiers )
    {
        payment = [SKPayment paymentWithProductIdentifier:identifier];
        
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

#pragma mark Private API

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    id <HKStorePurchase> purchase = [_purchases objectForKey:transaction.payment.productIdentifier];
    
    for ( id <HKStoreObserver> observer in _observers )
    {
        if ( [observer respondsToSelector:@selector(storeController:didFinishPurchase:receipt:)] )
        {
            [observer storeController:self didFinishPurchase:purchase receipt:transaction.transactionReceipt];
        }
    }
    
    [_purchases removeObjectForKey:transaction.payment.productIdentifier];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    id <HKStorePurchase> purchase = [_purchases objectForKey:transaction.payment.productIdentifier];
    
    for ( id <HKStoreObserver> observer in _observers )
    {
        if ( [observer respondsToSelector:@selector(storeController:didFinishPurchase:receipt:)] )
        {
            [observer storeController:self didFinishPurchase:purchase receipt:transaction.transactionReceipt];
        }
    }
    
    [_purchases removeObjectForKey:transaction.payment.productIdentifier];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    id <HKStorePurchase> purchase = [_purchases objectForKey:transaction.payment.productIdentifier];
    
    if ( transaction.error.code != SKErrorPaymentCancelled )
    {
        for ( id <HKStoreObserver> observer in _observers )
        {
            if ( [observer respondsToSelector:@selector(storeController:didFailPurchase:error:)] )
            {
                [observer storeController:self didFailPurchase:purchase error:transaction.error];
            }
        }
    }
    else
    {
        for ( id <HKStoreObserver> observer in _observers )
        {
            if ( [observer respondsToSelector:@selector(storeController:didCancelPurchase:)] )
            {
                [observer storeController:self didCancelPurchase:purchase];
            }
        }
    }
    
    [_purchases removeObjectForKey:transaction.payment.productIdentifier];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark SKRequestDelegate Methods

- (void)requestDidFinish:(SKRequest *)request
{
    [_requests removeObject:request];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    for ( id <HKStoreObserver> observer in _observers )
    {
        if ( [observer respondsToSelector:@selector(storeController:didFailWithError:)] )
        {
            [observer storeController:self didFailWithError:error];
        }
    }
}

#pragma mark SKProductsRequestDelegate Methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    id <HKStorePurchase> purchase;
    
    for ( SKProduct *storeProduct in response.products )
    {
        purchase = [_lookups objectForKey:storeProduct.productIdentifier];
        
        if ( purchase )
        {
            [purchase setPrice:[storeProduct price]];
            [purchase setPriceLocale:[storeProduct priceLocale]];
            
            for ( id <HKStoreObserver> observer in _observers )
            {
                if ( [observer respondsToSelector:@selector(storeController:didFinishLookupOfPurchase:)] )
                {
                    [observer storeController:self didFinishLookupOfPurchase:purchase];
                }
            }
            
            [_lookups removeObjectForKey:storeProduct.productIdentifier];
        }
    }
}

#pragma mark SKPaymentTransactionObserver Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for ( SKPaymentTransaction *transaction in transactions )
    {
        switch ( transaction.transactionState )
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
                
            default:
                break;
        }
    }
}

@end
