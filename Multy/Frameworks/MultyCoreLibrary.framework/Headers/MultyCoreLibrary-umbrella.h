#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import <Foundation/Foundation.h>

//#import "GGLInstanceID/GGLInstanceIDHeaders.h"

#import "account.h"
#import "api.h"
#import "big_int.h"
#import "binary_data.h"
#import "bip44_coin_types.h"
#import "bitcoin.h"
#import "blockchain.h"
#import "common.h"
#import "error.h"
#import "EOS.h"
#import "ethereum.h"
#import "golos.h"
#import "key.h"
#import "mnemonic.h"
#import "properties.h"
#import "run_tests.h"
#import "sha3.h"
#import "transaction_builder.h"
#import "transaction.h"

FOUNDATION_EXPORT double MultyCoreLibraryVersionNumber;
FOUNDATION_EXPORT const unsigned char MultyCoreLibraryVersionString[];

