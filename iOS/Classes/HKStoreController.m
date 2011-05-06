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

#import "HKStoreProduct.h"
#import "HKStoreObserver.h"

#import "NSString+HKFormatting.h"

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

- (void)release
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

- (void)lookupProducts:(NSSet *)products
{
    SKProductsRequest   *request;
    NSMutableSet        *identifiers = [NSMutableSet setWithCapacity:[products count]];
    NSString            *identifier;
    
    for ( id <HKStoreProduct> product in products )
    {
        identifier = [product productIdentifier];
        
        if ( identifier )
        {
            if ( [_lookups objectForKey:identifier] == nil )
            {
                [_lookups setObject:product forKey:identifier];
                
                [identifiers addObject:identifier];
            }
        }
    }
    
    request = [[[SKProductsRequest alloc] initWithProductIdentifiers:identifiers] autorelease];
    request.delegate = self;
    
    [_requests addObject:request];
    
    [request start];
}

- (void)purchaseProductsInSet:(NSSet *)products
{
    SKPayment           *payment;
    NSMutableSet        *identifiers = [NSMutableSet setWithCapacity:[products count]];
    NSString            *identifier;
    
    for ( id <HKStoreProduct> product in products )
    {
        identifier = [product productIdentifier];
        
        if ( identifier )
        {
            if ( [_purchases objectForKey:identifier] == nil )
            {
                [_purchases setObject:product forKey:identifier];
                
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
    id <HKStoreProduct> product = [_purchases objectForKey:transaction.payment.productIdentifier];
    
    for ( id <HKStoreObserver> observer in _observers )
    {
        if ( [observer respondsToSelector:@selector(storeController:didFinishPurchaseOfProduct:)] )
        {
            [observer storeController:self didFinishPurchaseOfProduct:product];
        }
    }
    
    [_purchases removeObjectForKey:transaction.payment.productIdentifier];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    id <HKStoreProduct> product = [_purchases objectForKey:transaction.payment.productIdentifier];
    
    for ( id <HKStoreObserver> observer in _observers )
    {
        if ( [observer respondsToSelector:@selector(storeController:didFinishPurchaseOfProduct:)] )
        {
            [observer storeController:self didFinishPurchaseOfProduct:product];
        }
    }
    
    [_purchases removeObjectForKey:transaction.payment.productIdentifier];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    id <HKStoreProduct> product = [_purchases objectForKey:transaction.payment.productIdentifier];
    
    if ( transaction.error.code != SKErrorPaymentCancelled )
    {
        for ( id <HKStoreObserver> observer in _observers )
        {
            if ( [observer respondsToSelector:@selector(storeController:didFailPurchaseOfProduct:error:)] )
            {
                [observer storeController:self didFailPurchaseOfProduct:product error:transaction.error];
            }
        }
    }
    else
    {
        for ( id <HKStoreObserver> observer in _observers )
        {
            if ( [observer respondsToSelector:@selector(storeController:didCancelPurchaseOfProduct:)] )
            {
                [observer storeController:self didCancelPurchaseOfProduct:product];
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
    id <SKStoreProduct> product;
    
    for ( SKProduct *storeProduct in response.products )
    {
        product = [_lookups objectForKey:storeProduct.productIdentifier];
        
        if ( product )
        {
            [product setFormattedPriceString:[NSString stringRepresentingNumberAsCurrency:storeProduct.price inLocale:storeProduct.priceLocale]];
            
            for ( id <HKStoreObserver> observer in _observers )
            {
                if ( [observer respondsToSelector:@selector(storeController:didFinishLookupOfProduct:)] )
                {
                    [observer storeController:self didFinishLookupOfProduct:product];
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
