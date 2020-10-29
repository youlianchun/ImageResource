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
@end

@implementation _BICacheNode
+ (instancetype _Nullable)nodeWithValue:(id)value key:(id<NSCopying>)key {
    if (value == nil || key == nil) return nil;
    _BICacheNode *node = [self new];
    node->_value = value;
    node->_key = key;
    return node;
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
}

- (void)_didReceiveMemoryWarningNotification {
    [self clean];
}

- (void)removeNodeForKey:(id<NSCopying>)key {
    _BICacheNode *node = _dict[key];
    if (!node) return;
    _BICacheNode *prev = node.prev;
    _BICacheNode *next = node.next;
    prev.next = next;
    next.prev = prev;
    _dict[key] = nil;
    node.next = nil;
    node.prev = nil;
    if (node == _headNode) {
        _headNode = next;
    }
    if (node == _tailNode) {
        _tailNode = prev;
    }
}

- (void)_setObject:(id)object forKey:(id<NSCopying>)key {
    [self removeNodeForKey:key];
    if (object) {
        _BICacheNode *node = [_BICacheNode nodeWithValue:object key:key];
        _dict[key] = node;
        _headNode.prev = node;
        node.next = _headNode;
        _headNode = node;
        if (!_tailNode) {
            _tailNode = node;
        }
        if (_dict.count > _capacity && _tailNode) {
            [self removeNodeForKey:_tailNode.key];
        }
    }
}

- (id)_objectForKey:(id<NSCopying>)key {
    _BICacheNode *node = _dict[key];
    if (node) {
        if (node != _headNode) {
            _BICacheNode *prev = node.prev;
            _BICacheNode *next = node.next;
            prev.next = next;
            next.prev = prev;
            node.next = _headNode;
            node.prev = nil;
            _headNode = node;
        }
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
