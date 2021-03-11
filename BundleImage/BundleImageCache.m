//
//  BundleImageCache.m
//  BundleImage
//
//  Created by YLCHUN on 2020/2/18.
//

#import "BundleImageCache.h"
#import <UIKit/UIApplication.h>
#import "pthread.h"

@interface _XMBICacheNode<KeyType, ObjectType> : NSObject
@property (nonatomic, strong, readonly) ObjectType value;
@property (nonatomic, strong, readonly) KeyType<NSCopying> key;
@property (nonatomic, strong) _XMBICacheNode<KeyType, ObjectType> *next;
@property (nonatomic, weak) _XMBICacheNode<KeyType, ObjectType> *prev;
@property (nonatomic, assign) time_t time;
@property (nonatomic, assign) BOOL protect;
@end

@implementation _XMBICacheNode
+ (instancetype _Nullable)nodeWithValue:(id)value key:(id<NSCopying>)key {
    if (value == nil || key == nil) return nil;
    _XMBICacheNode *node = [self new];
    node->_value = value;
    node->_key = key;
    return node;
}
@end


@implementation BundleImageCache
{
    pthread_mutex_t _mutex_t;
    NSMutableDictionary<id<NSCopying>, _XMBICacheNode *> *_dict;
    _XMBICacheNode *_headNode;
    __weak _XMBICacheNode *_tailNode;
}


- (instancetype)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_mutex_t, NULL);
        _dict = [NSMutableDictionary dictionary];
        _capacity = capacity;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (instancetype)init {
    return [self initWithCapacity:10];
}

- (void)dealloc {
    pthread_mutex_destroy(&_mutex_t);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_didReceiveMemoryWarningNotification {
    [self clean];
}

- (void)removeNodeForKey:(id<NSCopying>)key {
    _XMBICacheNode *node = _dict[key];
    if (!node) return;
    
    _XMBICacheNode *prev = node.prev;
    _XMBICacheNode *next = node.next;
    node.next = nil;
    node.prev = nil;
    _dict[key] = nil;

    if (prev) {
        prev.next = next;
    }
    else {
        _headNode = next;
        _headNode.prev = nil;
    }
    
    if (next) {
        next.prev = prev;
    }else {
        _tailNode = prev;
        _tailNode.next = nil;
    }
}

- (void)_setObject:(id)object forKey:(id<NSCopying>)key {
    BOOL protect = _dict[key].protect && [object isEqual:_dict[key].value];
    [self removeNodeForKey:key];
    if (object) {
        _XMBICacheNode *node = [_XMBICacheNode nodeWithValue:object key:key];
        node.time = time(NULL);
        node.protect = protect;
        _dict[key] = node;
        _headNode.prev = node;
        node.next = _headNode;
        if (!_headNode) {
            _tailNode = node;
        }
        _headNode = node;
        if (_capacity > 0) {
            NSInteger redundant = _dict.count - _capacity;
            _XMBICacheNode *node = _tailNode;
            for (NSInteger i = 0; i < redundant && node; i++) {
                if (node.protect) {
                    node = node.prev;
                    continue;
                }
                else {
                    if (node != _headNode) {
                        [self removeNodeForKey:node.key];
                    }
                    break;
                }
            }
        }
    }
}

- (id)_objectForKey:(id<NSCopying>)key {
    _XMBICacheNode *node = _dict[key];
    if (node) {
        if (node != _headNode) {
            _XMBICacheNode *prev = node.prev;
            _XMBICacheNode *next = node.next;
            prev.next = next;
            next.prev = prev;
            
            node.prev = nil;
            _headNode.prev = node;
            node.next = _headNode;
            _headNode = node;
            if (node == _tailNode) {
                _tailNode = prev;
            }
        }
        node.time = time(NULL);
    }
    return node.value;
}

- (void)_clean {
    [_dict removeAllObjects];
    _headNode = nil;
    _tailNode = nil;
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key {
    if (!key) return;
    pthread_mutex_lock(&_mutex_t);
    [self _setObject:object forKey:key];
    pthread_mutex_unlock(&_mutex_t);
}

- (id)objectForKey:(id<NSCopying>)key {
    if (!key) return nil;
    id value = nil;
    pthread_mutex_lock(&_mutex_t);
    value = [self _objectForKey:key];
    pthread_mutex_unlock(&_mutex_t);
    return value;
}

- (void)clean {
    pthread_mutex_lock(&_mutex_t);
    [self _clean];
    pthread_mutex_unlock(&_mutex_t);
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key {
    [self setObject:obj forKey:key];
}
- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}

- (void)protect:(id)key {
    if (!key) return;
    pthread_mutex_lock(&_mutex_t);
    _dict[key].protect = YES;
    pthread_mutex_unlock(&_mutex_t);
}

- (void)unprotect:(id)key {
    if (!key) return;
    pthread_mutex_lock(&_mutex_t);
    _dict[key].protect = NO;
    pthread_mutex_unlock(&_mutex_t);
}
@end

@implementation BundleImageCache(init)

- (id)objectForKey:(id<NSCopying>)key init:(id(^)(void))init {
    if (!key) return nil;
    id object = nil;
    pthread_mutex_lock(&_mutex_t);
    object = [self _objectForKey:key];
    if (!object && init) {
        object = init();
        if (object) {
            [self _setObject:object forKey:key];
        }
    }
    pthread_mutex_unlock(&_mutex_t);
    return object;
}
@end

@implementation BundleImageCache(patrol)

- (void)patrolTime:(NSTimeInterval)pt {
    if (pt <= 0) return;
    pthread_mutex_lock(&_mutex_t);
    time_t t = time(NULL);
    _XMBICacheNode *node = _tailNode;
    while (node) {
        if (node.protect || t - node.time < pt) {
            node = node.prev;
            continue;
        }
        [self removeNodeForKey:node.key];
    }
    pthread_mutex_unlock(&_mutex_t);
}

@end

@implementation BundleImageCache(lock)
- (void)lockBlock:(void(^)(void))block {
    if (!block) return;
    pthread_mutex_lock(&_mutex_t);
    block();
    pthread_mutex_unlock(&_mutex_t);
}
@end
