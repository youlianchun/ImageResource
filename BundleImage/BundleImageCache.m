//
//  BundleImageCache.m
//  BundleImage
//
//  Created by YLCHUN on 2020/2/18.
//

#import "BundleImageCache.h"
#import <UIKit/UIApplication.h>
#import "pthread.h"

@interface _BICacheNode<KeyType, ObjectType> : NSObject
@property (nonatomic, strong, readonly) ObjectType value;
@property (nonatomic, strong, readonly) KeyType<NSCopying> key;
@property (nonatomic, strong) _BICacheNode<KeyType, ObjectType> *next;
@property (nonatomic, weak) _BICacheNode<KeyType, ObjectType> *prev;
@property (nonatomic, assign) time_t time;
@end

@implementation _BICacheNode
+ (instancetype _Nullable)nodeWithValue:(id)value key:(id<NSCopying>)key {
    if (value == nil || key == nil) return nil;
    _BICacheNode *node = [self new];
    node->_value = value;
    node->_key = key;
    return node;
}
- (void)setNext:(_BICacheNode *)next {
    _next = next;
    if (_next == self) {
        NSLog(@"");
    }
}

@end


@implementation BundleImageCache
{
    pthread_mutex_t _mutex_t;
    NSMutableDictionary *_dict;
    _BICacheNode *_headNode;
    __weak _BICacheNode *_tailNode;
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)_didReceiveMemoryWarningNotification {
    [self clean];
}

- (void)removeNodeForKey:(id<NSCopying>)key {
    _BICacheNode *node = _dict[key];
    if (!node) return;
    
    _BICacheNode *prev = node.prev;
    _BICacheNode *next = node.next;
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
    if (_headNode == node || _tailNode == node) {
        NSLog(@"");
    }
    [self check];
}

- (void)_setObject:(id)object forKey:(id<NSCopying>)key {
    [self removeNodeForKey:key];
    if (object) {
        _BICacheNode *node = [_BICacheNode nodeWithValue:object key:key];
        node.time = time(NULL);
        _dict[key] = node;
        _headNode.prev = node;
        node.next = _headNode;
        if (!_headNode) {
            _tailNode = node;
        }
        _headNode = node;
        
        if (_capacity > 0 && _dict.count > _capacity) {
            if (!_tailNode) {
                NSLog(@"");
            }
            [self removeNodeForKey:_tailNode.key];
        }
    }
    [self check];
}

- (id)_objectForKey:(id<NSCopying>)key {
    _BICacheNode *node = _dict[key];
    if (node) {
        if (node != _headNode) {
            _BICacheNode *prev = node.prev;
            _BICacheNode *next = node.next;
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
    [self check];
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
    id object = nil;
    pthread_mutex_lock(&_mutex_t);
    object = [self _objectForKey:key];
    pthread_mutex_unlock(&_mutex_t);
    return object;
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

- (void)check {
    if (_headNode && !_tailNode) {
        NSLog(@"");
        _BICacheNode *node = _headNode;
        NSUInteger i = 1;
        while (node.next) {
            i ++;
            if (node.prev == nil && node != _headNode) {
                NSLog(@"");
            }
            node = node.next;
        }
        
        NSLog(@"");
    }
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

- (void)patrol:(time_t)pt {
    time_t t = time(NULL);
    while (_tailNode && t - _tailNode.time > pt) {
        [self removeNodeForKey:_tailNode.key];
    }
    [self check];
}

- (void)_patrolAfter:(NSNumber *)timeObj {
    NSTimeInterval time = timeObj.doubleValue;
    pthread_mutex_lock(&_mutex_t);
    [self patrol:time];
    pthread_mutex_unlock(&_mutex_t);
    if (time > 0) {
        [self patrolAfter:time];
    }
}

- (void)patrolAfter:(NSTimeInterval)time {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(_patrolAfter:) withObject:@(time) afterDelay:time];
    });
}

- (void)cancelPatrol {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    });
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
