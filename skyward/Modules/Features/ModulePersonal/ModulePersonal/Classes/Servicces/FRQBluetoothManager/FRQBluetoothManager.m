//
//  FRQBluetoothManager.m
//  FRQBluetoothKit
//
//  Created by chunhai xu on 2021/1/3.
//

#import "FRQBluetoothManager.h"
#import "FRIBluetooth.h"
#import "FRIUpdateOTAManager.h"
#import <CoreBluetooth/CBCentralManager.h>


#define FRQCheckStateError do { \
    if ([[FRQBluetoothManager shareManager] _checkStateError]) { \
        return; \
    }\
} while (0);


//特定的服务标识
#define kFRQServiceUUID @"FE00"
#define kFRQWriteCharacteristicUUID @"FF01"
#define kFRQReadCharacteristicUUID @"FF02"

@interface FRQBluetoothManager ()<FRIUpdateOTAManagerDelegate>

@property(nonatomic, strong) FRIUpdateOTAManager *updateOTAMgr; //!< 升级OTA
@property(nonatomic, strong) FRIBluetooth *friBLE; //!< 蓝牙工具

@property(nonatomic, assign) BOOL needUpdateOTA;

@end


@implementation FRQBluetoothManager
@synthesize state;

+(instancetype)shareManager{
    static FRQBluetoothManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FRQBluetoothManager alloc] init];
    });
    return instance;
}


- (instancetype)init
{
    if (self = [super init]) {
        
        //蓝牙外设处理类
        self.friBLE = [FRIBluetooth shareBluetooth];
        
//        //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
        NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@NO};
//        /*连接选项->
//         CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
//         CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
//         CBConnectPeripheralOptionNotifyOnNotificationKey:
//         当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提示
//        */
        NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@NO,
                                         CBConnectPeripheralOptionNotifyOnDisconnectionKey:@NO};
        [self.friBLE setFriOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];

        [self _setupBLECallbacks];
        
    }
    return self;
}


-(void)_setupBLECallbacks{
    
    __weak typeof(self) weakSelf = self;
    [self.friBLE setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        FRILog(@"on discover periheral %@, %@ !!",peripheral.name,advertisementData);

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([strongSelf.delegate respondsToSelector:@selector(onBLEManagerDiscoverPeripheral:peripheral:advertisement:RSSI:)]) {
                [strongSelf.delegate onBLEManagerDiscoverPeripheral:self peripheral:peripheral advertisement:advertisementData RSSI:RSSI];
            }
        });
        
    }];
    
    
    [self.friBLE setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        //本地先存储
        
        FRILog(@"===peripheral<%@> connected !!",peripheral.name);
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([strongSelf.delegate respondsToSelector:@selector(onBLEManagerConnect:peripheral:error:)]) {
                // 创建一个成功状态的 error
                NSError *successError = [NSError errorWithDomain:@"com.frq.bluetooth"
                                                            code:0  // 0 通常表示成功
                                                        userInfo:@{NSLocalizedDescriptionKey: @"连接成功",
                                                                   NSLocalizedFailureReasonErrorKey: @"设备已成功连接"}];
                [strongSelf.delegate onBLEManagerConnect:strongSelf peripheral:peripheral error:successError];
            }
        });
    }];
    
    [self.friBLE setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        FRILog(@"on discover characteristic for service %@!!",service.UUID.UUIDString);
        if ([service.UUID.UUIDString.uppercaseString containsString:kFRQServiceUUID]) {
            
            [strongSelf _checkAvaliableCharacters:peripheral service:service];
        }
    }];
    
    [self.friBLE setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            FRILog(@"💥💥💥💥on discover descriptors for characteristic %@, Error %@!!",characteristic.UUID.UUIDString,error);
        }
        else{
            FRILog(@"on discover descriptors for characteristic %@!!",characteristic.UUID.UUIDString);
        }
    }];
    
    [self.friBLE setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        //clean up
        [strongSelf cleanupForPeripheral:peripheral];
        
        FRILog(@"===fail to connect peripheral<%@> !! , error %@",peripheral.name,error);
        NSError *convertError = nil;
        if (error) {
            convertError = [FRQBluetoothManager convertErrFrom:error];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([strongSelf.delegate respondsToSelector:@selector(onBLEManagerConnect:peripheral:error:)]) {
                [strongSelf.delegate onBLEManagerConnect:strongSelf peripheral:peripheral error:convertError];
            }
        });

    }];
    
    [self.friBLE setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        FRILog(@"===discover <%@>  services %@ , error %@ !!",peripheral.name,peripheral.services,error);
    }];
    

    [self.friBLE setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        FRILog(@"===peripheral<%@> disconnected , error %@ !!",peripheral.name,error);
        NSError *convertError = nil;
        if (error) {
            convertError = [FRQBluetoothManager convertErrFrom:error];
            [strongSelf cleanupForPeripheral:peripheral];
        }
        
        if (strongSelf.updateOTAMgr.otaStatus == FRIOTAStatusFinish && self.needUpdateOTA) { //如果状态完成那么忽略错误提示
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([strongSelf.delegate respondsToSelector:@selector(onBLEManagerDisconnect:peripheral:error:)]) {
                [strongSelf.delegate onBLEManagerDisconnect:strongSelf peripheral:peripheral error:convertError];
            }
        });

    }];
    
    [self.friBLE setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *centralManager) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        strongSelf.state = centralManager.state;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([strongSelf.delegate respondsToSelector:@selector(onBLEManagerStateChange:)]) {
                [strongSelf.delegate onBLEManagerStateChange:strongSelf];
            }
            
            
            //如果蓝牙设备已经打开，那么返回
            if (strongSelf.state == CBCentralManagerStatePoweredOn && [strongSelf.friBLE allRestorePeripherals].count > 0) {
                
                for (CBPeripheral *restorePeripheral in [strongSelf.friBLE allRestorePeripherals]) {
                    [strongSelf cleanupForPeripheral:restorePeripheral];
                }
                
//                if ([strongSelf.delegate respondsToSelector:@selector(onBLEManager:willRestorePeripherals:)]) {
//                    [strongSelf.delegate onBLEManager:strongSelf willRestorePeripherals:strongSelf.friBLE.allRestorePeripherals];
//                }
            }
        });
        
    }];
    
    [self.friBLE setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([strongSelf.delegate respondsToSelector:@selector(onBLEManagerCancelScan:)]) {
                [strongSelf.delegate onBLEManagerCancelScan:strongSelf];
            }
        });
    }];
    
}

-(void)_checkAvaliableCharacters:(CBPeripheral *)peripheral service:(CBService *)service{
    
    CBCharacteristic *writeCharacteristic = nil;
    CBCharacteristic *readCharacteristic = nil;
    for (CBCharacteristic *character in service.characteristics) {
        
        if ([character.UUID.UUIDString.uppercaseString containsString:kFRQWriteCharacteristicUUID]
            && ((character.properties&CBCharacteristicPropertyWrite) || (character.properties&CBCharacteristicPropertyWriteWithoutResponse))) { //写
            writeCharacteristic = character;
            FRILog(@"⚽️⚽️⚽️⚽️⚽️⚽️get writable charact %@, %d",character, ((character.properties&CBCharacteristicPropertyWrite) || (character.properties&CBCharacteristicPropertyWriteWithoutResponse)));
        }
        else if ([character.UUID.UUIDString.uppercaseString containsString:kFRQReadCharacteristicUUID]
                 && (character.properties&CBCharacteristicPropertyRead)){ //读
            
            readCharacteristic = character;
            FRILog(@"⚽️⚽️⚽️⚽️⚽️⚽️get readable charact %@, %lu",character,character.properties&CBCharacteristicPropertyRead);
        }
    }
    
    if (self.needUpdateOTA) {
        //开始升级设备
        if (writeCharacteristic && readCharacteristic) {
            [self.updateOTAMgr startUpdateOTA:peripheral writeCharacteristic:writeCharacteristic readCharacteristic:readCharacteristic];
        }
        else{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(onBLEManagerUpdateOTAFinish:error:)]) {
                    NSError *error = [NSError errorWithDomain:@"设备无法读取或写入，请重试~" code:FRQErrorCode_ota userInfo:@{NSLocalizedFailureReasonErrorKey:@"设备无法读取或写入，请重试~",NSLocalizedDescriptionKey:@"设备无法读取或写入，请重试~"}];
                    [self.delegate onBLEManagerUpdateOTAFinish:self error:error];
                }
            });
            
        }
    }

}


#pragma mark -- public
- (void)setFilterForDiscoverPeripherals:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))discoverFilterBlock andFilterForConnectToPeripherals:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))connectFilterBlock{
    
    [self.friBLE setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (discoverFilterBlock) {
            return discoverFilterBlock(peripheralName, advertisementData, RSSI);
        }
        return YES;
    }];
    
    [self.friBLE setFilterOnConnectToPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (connectFilterBlock) {
            return connectFilterBlock(peripheralName, advertisementData, RSSI);
        }
        return YES;
    }];
    
}

- (void)scanPeripherals{
    
    FRQCheckStateError
    
    //扫描设备
    self.friBLE.scanForPeripherals().begin();
    
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral{
    
    FRQCheckStateError
    
    //只要是状态未连接那么开始连接
    self.needUpdateOTA = NO;
    
    //开始连接
    self.friBLE.having(peripheral).enjoy();

}

- (void)autoReconnectToPeripheral:(CBPeripheral *)peripheral{
    
    FRQCheckStateError
    
    [self connectToPeripheral:peripheral];
    //添加自动重连设备
    [self.friBLE AutoReconnect:peripheral];
    
}

- (void)closeAuotReconnectPeripheral:(CBPeripheral *)peripheral{
    
    [self closePeripheralConnection:peripheral];
    [self.friBLE AutoReconnectCancel:peripheral];
}

- (void)closePeripheralConnection:(CBPeripheral *)peripheral{
    [self.friBLE cancelPeripheralConnection:peripheral];
}


- (void)closeAllPeripheralsConnection{
    [self.friBLE cancelAllPeripheralsConnection];
}

- (NSArray *)allConnectedPeripherals{
    return [self.friBLE findConnectedPeripherals];
}

- (CBPeripheral *)findConnectedPeripheralWithName:(NSString *)peripheralName{
    return [self.friBLE findConnectedPeripheral:peripheralName];
}

- (BOOL)isScanning{
    return self.friBLE.centralManager.isScanning;
}

- (CBCentralManager *)centralManager{
    return self.friBLE.centralManager;
}

- (void)cancelScan{
    
    if (!self.isScanning) {
        return;
    }
    
    [self.friBLE cancelScan];
    
}


- (void)closeAllPeripheralsConnection:(nonnull void (^)(id<FRBleAbility> _Nonnull))block {

    __weak typeof(self) weakSelf = self;
    [self.friBLE setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        FRILog(@"cancel all peripherals connection !!!");

        if (block) {
            block(strongSelf);
        }
    }];
    
    [self.friBLE cancelAllPeripheralsConnection];
    
}

///OTA 
- (void)updateOTAWithFilePath:(NSString *)filePath  toPeripheral:(CBPeripheral*)perpheral{
    
    FRQCheckStateError
    
    if (filePath.length <= 0 || ![filePath.pathExtension isEqualToString:@"bin"]) {

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(onBLEManagerUpdateOTAFinish:error:)]) {
                NSError *error = [NSError errorWithDomain:@"文件路径错误，请重试~" code:FRQErrorCode_ota userInfo:@{NSLocalizedFailureReasonErrorKey:@"文件路径错误，请重试~",NSLocalizedDescriptionKey:@"文件路径错误，请重试~"}];
                [self.delegate onBLEManagerUpdateOTAFinish:self error:error];
            }
        });
        
        return;
    }
    else if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(onBLEManagerUpdateOTAFinish:error:)]) {
                NSError *error = [NSError errorWithDomain:@"文件不存在，请重试~" code:FRQErrorCode_ota userInfo:@{NSLocalizedFailureReasonErrorKey:@"文件不存在，请重试~",NSLocalizedDescriptionKey:@"文件路径错误，请重试~"}];
                [self.delegate onBLEManagerUpdateOTAFinish:self error:error];
            }
        });
        
        return;
    }
    
    NSData *otaData = [NSData dataWithContentsOfFile:filePath];
    [self updateOTAWithData:otaData toPeripheral:perpheral];
    
}

- (void)updateOTAWithData:(NSData *)binData  toPeripheral:(CBPeripheral*)perpheral{
    
    FRQCheckStateError
    
    //OTA升级管理
    self.updateOTAMgr.friBLE = self.friBLE;
    self.updateOTAMgr.binData = binData;
    [self.updateOTAMgr resetOTAStatus]; //状态重置
    
    self.needUpdateOTA = YES;
    
    //进行设备连接
    self.friBLE.having(perpheral).connectToPeripherals().discoverServices().discoverCharacteristics().discoverDescriptorsForCharacteristic().begin();
    
}

- (void)cancelOTAUpgrade{
    
    [_updateOTAMgr cancelOTAUpdate];
}


- (FRIUpdateOTAManager *)updateOTAMgr{
    if (!_updateOTAMgr) {
        _updateOTAMgr = [[FRIUpdateOTAManager alloc] init];
        _updateOTAMgr.delegate = self;
    }
    return _updateOTAMgr;
}



#pragma mark -- FRIUpdateOTAManagerDelegate
-(void)onOTAUpdateStart:(FRIUpdateOTAManager *)ota{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(onBLEManagerBeginUpdateOTA:)]) {
            [self.delegate onBLEManagerBeginUpdateOTA:self];
        }
    });
}

-(void)onOTAUpdateStatusDidChange:(FRIUpdateOTAManager *)ota withProgress:(float)aProgress{
    
    FRILog(@"========  OTA progress %.f =========",aProgress);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.delegate respondsToSelector:@selector(onBLEManagerUpdateOTA:progress:)]) {
            [self.delegate onBLEManagerUpdateOTA:self progress:aProgress];
        }
    });
    
}

-(void)onOTAUpdateStatusCompletion:(FRIUpdateOTAManager *)ota{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.delegate respondsToSelector:@selector(onBLEManagerUpdateOTAFinish:error:)]) {
            // 确保error不为nil
            NSError *error = [NSError errorWithDomain:@"com.frq.ota"
                                                 code:0
                                             userInfo:nil];
            [self.delegate onBLEManagerUpdateOTAFinish:self error:error];
        }
    });
}

-(void)onOTAUpdateStatusFailure:(FRIUpdateOTAManager *)ota error:(NSError *)err{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(onBLEManagerUpdateOTAFinish:error:)]) {
            [self.delegate onBLEManagerUpdateOTAFinish:self error:err];
        }
    });

}

#pragma mark -- doCheckCentralState
-(BOOL)_checkStateError{
    
    
    if (self.state == FRQManagerStatePoweredOn || self.state == FRQManagerStateUnknown) {
        return NO;
    }
    
    NSString *stateErrMsg = @"设备连接失败，请重试~";
    if (self.state == FRQManagerStateUnsupported) {
        stateErrMsg = @"不支持蓝牙设备";
    }
    else if (self.state == FRQManagerStateUnauthorized){
        stateErrMsg = @"蓝牙设备未授权，请在设置中开启后重试~";
    }
    else if (self.state == FRQManagerStatePoweredOff){
        stateErrMsg = @"蓝牙设备已关闭，开启后重试~";
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *errMsg = [NSString stringWithFormat:@"<%@>%@",@(self.state),stateErrMsg];
        if ([self.delegate respondsToSelector:@selector(onBLEManagerUpdateOTAFinish:error:)]) {
            NSError *error = [NSError errorWithDomain:errMsg code:FRQErrorCode_connect userInfo:@{NSLocalizedFailureReasonErrorKey:errMsg,NSLocalizedDescriptionKey:errMsg}];
            [self.delegate onBLEManagerUpdateOTAFinish:self error:error];
        }
    });
    
    return YES;
}


+(NSError *)convertErrFrom:(NSError *)err{
    
    
//    CBErrorInvalidParameters NS_ENUM_AVAILABLE(10_9, 6_0)        = 1,
//    CBErrorInvalidHandle NS_ENUM_AVAILABLE(10_9, 6_0)            = 2,
//    CBErrorNotConnected NS_ENUM_AVAILABLE(10_9, 6_0)            = 3,
//    CBErrorOutOfSpace NS_ENUM_AVAILABLE(10_9, 6_0)                = 4,
//    CBErrorOperationCancelled NS_ENUM_AVAILABLE(10_9, 6_0)        = 5,
//    CBErrorConnectionTimeout NS_ENUM_AVAILABLE(10_9, 6_0)        = 6,
//    CBErrorPeripheralDisconnected NS_ENUM_AVAILABLE(10_9, 6_0)    = 7,
//    CBErrorUUIDNotAllowed NS_ENUM_AVAILABLE(10_9, 6_0)            = 8,
//    CBErrorAlreadyAdvertising NS_ENUM_AVAILABLE(10_9, 6_0)        = 9,
//    CBErrorConnectionFailed NS_ENUM_AVAILABLE(10_13, 7_1)        = 10,
//    CBErrorConnectionLimitReached NS_ENUM_AVAILABLE(10_13, 9_0)    = 11,
//    CBErrorUnkownDevice NS_ENUM_DEPRECATED(10_13, 10_15, 9_0, 13_0, "Use CBErrorUnknownDevice instead") = 12,
//    CBErrorUnknownDevice NS_ENUM_AVAILABLE(10_14, 12_0)            = 12,
//    CBErrorOperationNotSupported NS_ENUM_AVAILABLE(10_14, 12_0)    = 13,
//    CBErrorPeerRemovedPairingInformation NS_ENUM_AVAILABLE(10_15, 13_4)    = 14,
//    CBErrorEncryptionTimedOut NS_ENUM_AVAILABLE(10_15, 13_3)    = 15,
//    CBErrorTooManyLEPairedDevices NS_ENUM_AVAILABLE(11_0, 14_0) = 16,
    
    NSString *msg = @"未知错误，请重试";
    switch (err.code) {
        case CBErrorConnectionTimeout:
            msg = @"设备连接超时";
            break;
        case CBErrorOperationCancelled:
            msg = @"操作被取消";
            break;
        case CBErrorAlreadyAdvertising:
            msg = @"设备已订阅";
            break;
        case CBErrorOperationNotSupported:
            msg = @"操作不支持";
            break;
        case CBErrorConnectionLimitReached:
            msg = @"设备连接数已达上限";
            break;
        case CBErrorEncryptionTimedOut:
            msg = @"加密超时";
            break;
        case CBErrorConnectionFailed:
            msg = @"连接失败";
            break;
        case CBErrorPeerRemovedPairingInformation:
            msg = @"设备配对信息已删除";
            break;
        default:
            break;
    }
    NSString *localMessage = [NSString stringWithFormat:@"<%@>%@",@(err.code),msg];
    return [NSError errorWithDomain:localMessage code:FRQErrorCode_connect userInfo:@{NSLocalizedDescriptionKey:localMessage,
                                                                          NSLocalizedFailureReasonErrorKey:localMessage}];
}


//This is called when things either go wrong, or we are done with the connection. This cancels any subscriptions if there are any, or straight disconnects if not.
- (void)cleanupForPeripheral:(CBPeripheral *)peripheral
{
    //See if we are subscribed to a characteristic on the peripheral
    if(peripheral.services.count > 0){
        //Loop through all service
        [peripheral.services enumerateObjectsUsingBlock:^(CBService *service, NSUInteger idx, BOOL *stop) {
            //Loop through all the services characteristics
            [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic *characteristic, NSUInteger idx, BOOL *stop) {
                
                //And is the one we are listening to
                if([characteristic isNotifying])
                {
                    //Unsubscribe
                    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
                }
            }];
        }];
    }
    
    //If it jumps to here, we're connected, but we're not subscribed, so we just disconnect
    [self.friBLE cancelPeripheralConnection:peripheral];
    
}

@end
