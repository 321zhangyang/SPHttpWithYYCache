//
//  SPHttpWithYYCache.m
//  SPHttp
//
//  Created by 换一换 on 16/3/8.
//  Copyright © 2016年 张洋. All rights reserved.
//

#import "SPHttpWithYYCache.h"
#import "AFNetworking.h"
#import <YYCache/YYCache.h>
//YYCache
NSString * const SPHttpCache = @"SPHttpCache";
#define MCLog(...) NSLog(__VA_ARGS__)  //如果不需要打印数据, 注释掉NSLog

// 请求方式
typedef NS_ENUM(NSInteger, RequestType) {
    RequestTypeGet,
    RequestTypePost,
    RequestTypeUpLoad,
    RequestTypeDownload
};

@implementation SPHttpWithYYCache

+(void)getRequestUrlStr:(NSString *)urlStr success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [[self alloc] requestWithUrl:urlStr withDic:nil requestType:RequestTypeGet isCache:NO cacheKey:nil imageKey:nil withData:nil upLoadProgress:nil success:^(NSDictionary *requestDic, NSString *msg) {
        success(requestDic,msg);
    } failure:^(NSString *errorInfo) {
        
    }];
}




+(void)getRequestCacheUrlStr:(NSString *)urlStr success:(SuccessBlock)success failure:(FailureBlock)failuer{

    [[self alloc] requestWithUrl:urlStr withDic:nil requestType:RequestTypeGet isCache:YES cacheKey:urlStr imageKey:nil withData:nil upLoadProgress:nil success:^(NSDictionary *requestDic, NSString *msg) {
        success(requestDic,msg);
    } failure:^(NSString *errorInfo) {
        
    }];
}


+(void)postRequestUrlStr:(NSString *)urlStr withDic:(NSDictionary *)parameters success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [[self alloc] requestWithUrl:urlStr withDic:parameters requestType:RequestTypePost isCache:NO cacheKey:urlStr imageKey:nil withData:nil upLoadProgress:nil success:^(NSDictionary *requestDic, NSString *msg) {
        success(requestDic,msg);
    } failure:^(NSString *errorInfo) {
        
    }];
}

+(void)postREquestCacheUrlStr:(NSString *)urlStr withDic:(NSDictionary *)parameters success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [[self alloc] requestWithUrl:urlStr withDic:parameters requestType:RequestTypePost isCache:YES cacheKey:urlStr imageKey:nil withData:nil upLoadProgress:nil success:^(NSDictionary *requestDic, NSString *msg) {
        success(requestDic,msg);
    } failure:^(NSString *errorInfo) {
        
    }];
}

+(void)upLoadDataWithUrlStr:(NSString *)urlStr withDic:(NSDictionary *)parameters imageKey:(NSString *)attach withData:(NSData *)data upLoadProgress:(loadProgress)loadProgress success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [[self alloc]requestWithUrl:urlStr withDic:parameters requestType:RequestTypeUpLoad isCache:NO cacheKey:urlStr imageKey:attach withData:data upLoadProgress:^(float progress) {
        loadProgress(progress);
    } success:^(NSDictionary *requestDic, NSString *msg) {
        success(requestDic,msg);
    } failure:^(NSString *errorInfo) {
        
    }];
}
#pragma mark -- 网络请求统一处理
-(void)requestWithUrl:(NSString *)url withDic:(NSDictionary *)parameters requestType:(RequestType)requestType  isCache:(BOOL)isCache  cacheKey:(NSString *)cacheKey imageKey:(NSString *)attach withData:(NSData *)data upLoadProgress:(loadProgress)loadProgress success:(SuccessBlock)success failure:(FailureBlock)failure
{
    
    //处理中文和空格问题
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    //拼接
    NSString * cacheUrl = [self urlDictToStringWithUrlStr:url WithDict:parameters];
    
    MCLog(@"\n\n 网址 \n\n      %@    \n\n 网址 \n\n",cacheUrl);
    //设置YYCache属性
     YYCache *cache = [[YYCache alloc] initWithName:SPHttpCache];

    cache.memoryCache.shouldRemoveAllObjectsOnMemoryWarning = YES;
    cache.memoryCache.shouldRemoveAllObjectsWhenEnteringBackground = YES;
    

    id cacheData;
    
    if (isCache) {
    
        //根据网址从Cache中取数据
        cacheData = [cache objectForKey:cacheKey];
        
   
        if (cacheData != 0) {
            //将数据统一处理
            [self returnDataWithRequestData:cacheData Success:^(NSDictionary *requestDic, NSString *msg) {
                MCLog(@"缓存数据\n\n    %@    \n\n",requestDic);
                success(requestDic,msg);
            } failure:^(NSString *errorInfo) {
                failure(errorInfo);
            }];
            

        }
    }
    
    //进行网络检查
    
    if (![self requestBeforeJudgeConnect]) {
        failure(@"没有网络");
        MCLog(@"\n\n----%@------\n\n",@"没有网络");
        return;
    }
    
    
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    
    session.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html", nil];
    session.requestSerializer.timeoutInterval =  10;
    
    session.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    //get请求
    if (requestType == RequestTypeGet) {
        [session GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
          
            
            [self dealWithResponseObject:responseObject cacheUrl:cacheUrl cacheData:cacheData isCache:isCache cache:cache cacheKey:cacheKey success:^(NSDictionary *requestDic, NSString *msg) {
                
            } failure:^(NSString *errorInfo) {
                
            }];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure(@"出现问题了");
        }];
        
    }
    
    //post请求
    if (requestType == RequestTypePost) {
        
        [session POST:url parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
            [self dealWithResponseObject:responseObject cacheUrl:cacheUrl cacheData:cacheData isCache:isCache cache:cache cacheKey:cacheKey success:^(NSDictionary *requestDic, NSString *msg) {
                
            } failure:^(NSString *errorInfo) {
                
            }];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure(@"出现问题了");
        }];
    }
    
    //上传
    if (requestType == RequestTypeUpLoad) {
        [session POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSTimeInterval timeInterVal = [[NSDate date] timeIntervalSince1970];
            NSString * fileName = [NSString stringWithFormat:@"%@.png",@(timeInterVal)];
            [formData appendPartWithFileData:data name:attach fileName:fileName mimeType:@"image/png"];
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            
            
            loadProgress((float)uploadProgress.completedUnitCount/(float)uploadProgress.totalUnitCount);
            
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
        
            
            [self dealWithResponseObject:responseObject cacheUrl:cacheUrl cacheData:cacheData isCache:isCache cache:nil cacheKey:nil success:^(NSDictionary *requestDic, NSString *msg) {
                success(requestDic,msg);
            } failure:^(NSString *errorInfo) {
                   failure(errorInfo);
            }];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure(@"出现错误了");
            MCLog(@"上传文件发生错误\n\n    %@  \n\n",error);
        }];
        
   
        
        
    }
   
    
    
    
    
    
    
    
}




#pragma mark  统一处理请求到的数据
-(void)dealWithResponseObject:(NSData *)responseData cacheUrl:(NSString *)cacheUrl cacheData:(id)cacheData isCache:(BOOL)isCache cache:(YYCache*)cache cacheKey:(NSString *)cacheKey success:(SuccessBlock)success failure :(FailureBlock)failure
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;// 关闭网络指示器
    });
    
    
    NSString * dataString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    dataString = [self deleteSpecialCodeWithStr:dataString];
    NSData *requestData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (isCache) {
        //
        [cache setObject:requestData forKey:cacheKey];
        
    }
    //如果不缓存 或者 数据不相同 从网络请求
    if (!isCache || ![cacheData isEqual:requestData]) {
      
        [self returnDataWithRequestData:requestData Success:^(NSDictionary *requestDic, NSString *msg) {
            MCLog(@"网络数据\n\n   %@   \n\n",requestDic);
        } failure:^(NSString *errorInfo) {
            failure(errorInfo);
        }];
    }
    
    
}


/**
 *  拼接post请求的网址
 *
 *  @param urlStr     基础网址
 *  @param parameters 拼接参数
 *
 *  @return 拼接完成的网址
 */
-(NSString *)urlDictToStringWithUrlStr:(NSString *)urlStr WithDict:(NSDictionary *)parameters
{
    if (!parameters) {
        return urlStr;
    }
    
    
    NSMutableArray *parts = [NSMutableArray array];
    //enumerateKeysAndObjectsUsingBlock会遍历dictionary并把里面所有的key和value一组一组的展示给你，每组都会执行这个block 这其实就是传递一个block到另一个方法，在这个例子里它会带着特定参数被反复调用，直到找到一个ENOUGH的key，然后就会通过重新赋值那个BOOL *stop来停止运行，停止遍历同时停止调用block
    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        //接收key
        NSString *finalKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        //接收值
        NSString *finalValue = [obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        
        NSString *part =[NSString stringWithFormat:@"%@=%@",finalKey,finalValue];
        
        [parts addObject:part];
        
    }];
    
    NSString *queryString = [parts componentsJoinedByString:@"&"];
    
    queryString = queryString ? [NSString stringWithFormat:@"?%@",queryString] : @"";
    
    NSString *pathStr = [NSString stringWithFormat:@"%@?%@",urlStr,queryString];
    
    return pathStr;
    
    
    
}


#pragma mark --根据返回的数据进行统一的格式处理  ----requestData 网络或者是缓存的数据----
- (void)returnDataWithRequestData:(NSData *)requestData Success:(SuccessBlock)success failure:(FailureBlock)failure{
    id myResult = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingMutableContainers error:nil];
    
    
    //判断是否为字典
    if ([myResult isKindOfClass:[NSDictionary  class]]) {
        NSDictionary *  requestDic = (NSDictionary *)myResult;
        
        //根据返回的接口内容来变
        NSString * succ = requestDic[@"status"];
        if ([succ isEqualToString:@"success"]) {
            success(requestDic[@"result"],requestDic[@"msg"]);
        }else{
            failure(requestDic[@"msg"]);
        }
        
    }
    
}

#pragma mark  网络判断
-(BOOL)requestBeforeJudgeConnect
{
    struct sockaddr zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sa_len = sizeof(zeroAddress);
    zeroAddress.sa_family = AF_INET;
    SCNetworkReachabilityRef defaultRouteReachability =
    SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    BOOL didRetrieveFlags =
    SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    if (!didRetrieveFlags) {
        printf("Error. Count not recover network reachability flags\n");
        return NO;
    }
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL isNetworkEnable  =(isReachable && !needsConnection) ? YES : NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible =isNetworkEnable;/*  网络指示器的状态： 有网络 ： 开  没有网络： 关  */
    });
    return isNetworkEnable;
}

#pragma mark -- 处理json格式的字符串中的换行符、回车符
- (NSString *)deleteSpecialCodeWithStr:(NSString *)str {
    NSString *string = [str stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
    return string;
}

@end
