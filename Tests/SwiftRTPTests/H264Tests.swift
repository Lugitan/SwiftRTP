import XCTest
@testable import BinaryKit
@testable import SwiftRTP

final class H264Tests: XCTestCase {
    func testNALUnitTypeName() {
        for type in H264.NALUnitType.allCases {
            XCTAssertFalse(type.description.contains("Unkown"))
        }
    }
    func testNALUnitHeaderReadAndWriteFromStruct() throws {
        let headers = [
            H264.NALUnitHeader(forbiddenZeroBit: false, referenceIndex: 0, type: .fragmentationUnitA),
            H264.NALUnitHeader(forbiddenZeroBit: true, referenceIndex: 0, type: .fragmentationUnitB),
            H264.NALUnitHeader(forbiddenZeroBit: false, referenceIndex: 1, type: .reserved31),
            H264.NALUnitHeader(forbiddenZeroBit: false, referenceIndex: 2, type: .multiTimeAggregationPacket16),
            H264.NALUnitHeader(forbiddenZeroBit: false, referenceIndex: 3, type: .singleTimeAggregationPacketA),
        ]
        for header in headers {
            var writer = BinaryWriter()
            try header.write(to: &writer)
            var reader = BinaryReader(bytes: writer.bytesStore)
            XCTAssertEqual(header, try H264.NALUnitHeader(from: &reader))
        }
    }
    
    func testReadHeaderFromBinary() throws {
        var header = BinaryReader(bytes: [0b1_01_10000])
        //                                  | |  |
        //                                  | |  type
        //                                  | reference index
        //                                  forbidden zero bit
        XCTAssertEqual(
            try H264.NALUnitHeader(from: &header),
            H264.NALUnitHeader(
                forbiddenZeroBit: true,
                referenceIndex: 1,
                type: .init(rawValue: 16)
            ))
    }
    func testWriteHeaderToBinary() throws {
        var writer = BinaryWriter(bytes: [])
        try H264.NALUnitHeader(
            forbiddenZeroBit: false,
            referenceIndex: 2,
            type: .init(rawValue: 16)
        ).write(to: &writer)
        
        XCTAssertEqual(writer.bytesStore, [0b0_10_10000])
        //                                   | |  |
        //                                   | |  type
        //                                   | reference index
        //                                   forbidden zero bit
    }
    
    func testSingleTimeAggregationPacket() throws {
        let singleTimeAggregationPacketAWithSPSAndPPS = "1800176742c028da01e0089f97011000003e90000bb800f1832a000468ce3c80"
        var reader = try XCTUnwrap(BinaryReader(hexString: singleTimeAggregationPacketAWithSPSAndPPS))
        var a = H264.NALNonInterleavedPacketParser<[UInt8]>()
        let nalus = try a.readPackage(from: &reader)
        let sps = try XCTUnwrap(nalus.first)
        let pps = try XCTUnwrap(nalus.last)
        XCTAssertEqual(sps.header, H264.NALUnitHeader(forbiddenZeroBit: false, referenceIndex: 3, type: .sequenceParameterSet))
        XCTAssertEqual(sps.payload.count, 22)
        XCTAssertEqual(pps.header, H264.NALUnitHeader(forbiddenZeroBit: false, referenceIndex: 3, type: .pictureParameterSet))
        XCTAssertEqual(pps.payload.count, 3)
    }
    
    func testFragmentedPacketA() throws {
        var startPacket = try XCTUnwrap(BinaryReader(hexString:  "5c819be08800670444be0026bf2648723fe940484be00bc0cb732593f84fffff011ebdb79a117822237e7945f89f08cbc7e5453f84f0004114a42042494a5041049247ffe000747fd813075efe0ba4f0ce1525fe60340202e00b8d582796fc83c5a94dbf0f196f1e5ea583934d1fc40b81a498070219e03dd1cd27e5f65b7263c8662cb0390cc5960090dad30ade4cf5a69b50780ac06dfa7e8fe13c0022001a18b2d6b507245cb96fff002e99b216573080e00f2c1f15c8a7a7073b730a6625fec32433c8648679ff9bc0841e5ffbbcb97092a6cdc65b80389973ef89c0c5cd800ad66c8515d1c83d750568050abdcc140444c00a94c80fe021b79ec522bc67a70abf0267a1b23a3ff3c31ed9fa5c6f686639eea912547be23c2785540fef5adef5ae7f8812128422920a6e6d9108fbd4b0cbe024ef4b7d8345e0557e542d7b6c44dc7628066bfd4b2f9899784e3fa61aad7781feb9337ba3cd87f87c07000d817e005a9e827282157aef823db3b608c96089f01803b000459e0ed21b1034b74680b0a34cb6362aff7e97e320fe1e9b1ec445ee3faf0a60094188c8896b58c6cfff002ac49be81ec703dfb80989f81851a49c06d579c484bf77df07d0f722a2f077e0c0082320022578da56a1ca0506805895280056f460a5ce0616cfec061aa19e4815a0f69f5af3f7f918d983c575cf0a304505af40cbcf7a09e00088cc884eaaa888aedfffc00719e85730a26dfb8447450001023801763cc841c49913b60024cf20b3b8001cc91d8ef2f5fbfe98cb8702e8be58ce7056dff8318f84f0e94cf9612c3e584b09ff89f048b874b0df463c44de2632a2040a84792c26fc979ecff0d54907d16018c47f81c440980131d515355ddf9ef1ae2233b55e3918f107971ef1e0214f2d339f79fe10072260176cb5c36bcf3e35f6f607fb35dbbaa0c5630043425a1dbb3c1f13332d755b1fc48ee03889f4b00212d94f21c47f005d8e469738e78cfbfeffc17f0196000204995cc35b8060ebcf01c2030af0577016114acc22111f928b43281527aff19aded9ae6ff06a6b2e573a9566ffa9f37822872474b331ec81f398d36adfb5000dd5b81a8671a75eb1049929fee0af730886709e03cc345a8a0467b4f05096cdc973d58075acd4026af019d5445ffba550f5a0133c3c037c04a2ce4bd678042008d5325e182500008022e0850c6ab179e20140097215eeaea3ffffef007646e2cf6034006409981808db758b11887eb033570c27ac920f9787c0d20846426d68799c000e00acb2cc0a90afe3c2e9e09d81cc3e77c0fcab6837603033dfafab3f0012ab706f08043fc0439e0aa0696231c0d6c406052d3f3c200791f0fb2c9d96fc0247b8d196d6d208b25bef81b75ba8f1990fa032de2111e006116413ba5e7b23f7835bc060cfee9ffc220284678018c906b308bc001113c46e09e59e376e67b18a2a658c45bcdce7a50724e0e12c69670f3bdf600526c46852b5880152bcf804151e3c7dff808136095aec001afd1460748cbf063cfbc2780106da5b69cfe011b57e7c81042dc80ca591c999e1093ffd5080c1b2c0e88040f96a307440207cb0d080c1f2dc40ee43a082dd906393fb90e7860052dc631338e68d383f150eb8b4891ec0193ec493950f0753119d48883c0f8fee6ce0532f3ca61043884fcf15bc2f59bc015a372e3d3f0309fcfe13c664990743cef9de8743cef9df3f9fc47f11f8600b2118a4630474b2f0c4811c089561c59c28dfbde3332027e252171eb000c5b42883535e0bfda6ddfbf5ffdbb8325429b67de1f812457804de7d57f6f0d4e3c58fc278032491222001802f5505ae67826442df3b6ab417400079ef640a8d78e004af9130001003b98798000801dcc1c0022be0e0013bf80b000f08f87d964ecb7af6a76feae6d0dc055498f590175882ea48baaa27e13c0082e0c24c428973a428833d808926739e98008c986ce48512204347c5587021b6e709e00d52b6a3d33e67eb06a0f9573cd81005dee4cf99ed807002a5b8d80700a96e61001202b0015e5c21ef"))
        var middlePacket = try XCTUnwrap(BinaryReader(hexString:  "5c010423ffdd031b76441ece8b7fe002227902853b1f18cfd57c26dc9845c0744be18b2b2c0cfe49a2224abdf7012013d9117d0c5696d7f60cf1ef87a5efc022002806400b72191e23a65c0001026779e00f5460f7f4c0c086308f0ca31c3ac82fdbc0f0002ea50c795392cb7192a492455f421210501ae806fc02f2c925c94084b93181e9ff042020711f0a7fffff80063ab6f449bc1000e81d8216ff2047699767ac8125ad1fa8292fbc18701253701f8d7f1fae4bfb49489b2cdde81e0800740ac420a01774c1eb22b004efd0c23eb0096e8ce5c62aabb0128d64f0c4d456fb839ff0309fcfe7f3f9fcff014003802380091f9c21886c8277f8005c67c5686acf7d36fbf3cda0015899f2a2c329bfe0004c8bccc1fb8228848b4e0b7fe186cc3fdeb52189f7061f03c00441f32edec77f77ff0c3e06001703b0016b6b18dd3e5b1c82416f7396229bc05db1f5c418e10ef6de1c002fd14cf9e427dc180b448a558e14a7fc1c2780219b99a693fef7ffc05554d6601e18a15973559f09e00093ca4f30c8917ef075bee2de41d6f058fed6783ade3220974efd40eb794505a8173d3fe013001f22a01b4045588395aec285845b35c247daa66a44ef09e001107e9233c88ffd7e01270f44bde4ea018d086b302800a91d305c003460d7a2206e6c93f7e00b3998891ced91edd5a3c7bff4768c2f31d88bf5e1d40ad7393c4ce6078640649300505a28bafbb4610c8003b9267435d9bb27de290a7e698001ef380835c760f3af034d76be0380439d147fe13ffff9a134308c6424fb5600a9c3ef60a7692168032183baf831b2e75bf3ba1f7878f4e41f67105acdbf7cc098652660164a9408d6d3ee384fffff0085abfdb0110026466006d9bd13c81fa5b40fcc085f806657fc56300010072106f1edad59a2d95daf1e4925e4830207b5e29bb7258af7437f3fa0ed8346977073ffcf036312ff36001917c8acfafffe0230db9f9821d2b5b890ac77a61089c0073d147a1a3bc801b73967765dbf1661fca254f37ffa830f3f0309fcfe7f3f9fe03240608cf00889b24ebc8001cbdb202415ac7e70410e790128b0efecf84cf6317ac0e10335ef1e1a9a51be00088e67a0487393cb0ed7b07fb5981c3647b31a95dd7b5e2ff83f897d9fcc754bffb030f8044405c8c8ff85de5b009914c1f66f0009e890c3feb9a0cb0491482cccc6598a37864c1890b6061d890bb92881084a86f3f6cc201c3e5b02a532da64385cafd45a14c1c3a496925c69d4d269b4d60e00440462219bc0ac0f01879a5a026ac198fe02fb8d21fd8449116e8ce9e00146e123bb02f18e78f000829406267e07327f818c925e32fd0444ff116b014c790affffed3effb7f7f806640a010805be404f1c33a8f03995b21921c10085fbee80008137006441b4901c80eef8b00010229e000204930fbad81ec28a5ec62e07d913d00008113f360ef2b95a1e023b7ec02800591d8017c33a34a041f90b1341608bd69d734ff8343f5b1302bc41df2b74aea322a81f610044bc5fa4278002a1c2149a8cf364a0827f01eb04d37cf051d01ff20246a81cce3b70098221538cbcf101500b701f3987b52009ee202a016e62210ba8626d12c27b3d0fcdbfb00676c5f6a8bd1d1c100fe17b14fc0fc1b4676c913be0be003ca21145a6cff853311ffd8c98ce632633e1001922e00804e989b95f813115674c8f7aff06d80d3e5a01207df5cc6c254e6094a470ab43887ce99642797ffffcb09618801a03310f300401c6738846282b9fd822fcd40cb7ffdd7981118a4cc011206ab50d80de2fcb906bea9540891046c57bd81f15ade839d98848cdd7bff80f8024846367608c85482456b5ef2df800ef48516d167d0cf81800d355eca3cf019b0a5fa9e91cddf01ade4c44e5e0e5897e7838c6aa47ddffff366f0011ab37a25effff0162038464c94000a1c8b4ad4807047037ef859f076b2e033826c4c755e4306304177c1ef71ad8bb3a9e0091b33b111464bb1010143fc1f5687a1c43fc2e78e22de980bbf853311ff0ff96ae5fab96"))
        var endPacket = try XCTUnwrap(BinaryReader(hexString:  "5c41ae5fc278004606f8c88e322ff007f7c68871583c80231573f0309fcff04210084070473de99838214d2533070429a4a66009d8dd6abbaad0e6fbc1e5b9607af9684f0004934c118f9798e6157ff870700d2c0b9608c3ce6ff09e0082640cca7320eaf80238fb114b9f4800421b73e300118dd6403c712b16317301a010086a18ea9d5d6b807ff57cf40395b96c1cadcb18bc0214fffc69e9a711e23e0e40202260e004394f4cc061111f53179f78399e4022e576fe7bc03114c70f03cc33d01e2004404200ac82d1c54498810debc25d98108b4382d7db80ada1a299d97fbde0d19948d8eaadf18ed28697f6eeb00aab9dcebb594c9cd6b534137ec0b2024021001a52248a57f7ffff1593c6b183de49fd1aaf042b4ebbcf81c4044847cbfc51a025039c56627fc80010d6c6224550e45f8175307fd01902ef9d9342bd6a52bb00a00164760218248e2bf9fc0006d8534b5402c050b3c757c4ac433db95442a9a7283e97ff93eb72a1f5277f340c41cf7d030f3fcfe13c001064214a521084395c826fe6b9ebae7ebae6bae071400052e14c0ecdafc76e56dce34eb6e271e0a00c23ee26d998d63dff0065443e594fa9e033a490255fc712cdebfd4f5f7a1fef17f725ec11c5f2045be407b343cfdec06b10c30205fe5e2c41ebe5b07adcb103f3ca14ffff79a39ace68e6a2378535f99f1db9f5b73c2780087d77ddffff003f094a48c5cff00080dc"))
        
        
        var parser = H264.NALNonInterleavedPacketParser<[UInt8]>()
        XCTAssertEqual(try parser.readPackage(from: &startPacket), [])
        XCTAssertEqual(try parser.readPackage(from: &middlePacket), [])
        let nalu = try XCTUnwrap(try parser.readPackage(from: &endPacket).first)
        XCTAssertEqual(nalu.header, H264.NALUnitHeader(forbiddenZeroBit: false, referenceIndex: 2, type: .init(rawValue: 1)))
        XCTAssertEqual(nalu.payload.count, 3437)
    }
    
    func testNALUnitToBytes() {
        let nalu = H264.NALUnit(header: .init(forbiddenZeroBit: false, referenceIndex: 0, type: .pictureParameterSet), payload: Data([1,2,3,4,5,6,7,8]))
        XCTAssertEqual(nalu.bytes, Data([H264.NALUnitType.pictureParameterSet.rawValue, 1,2,3,4,5,6,7,8]))
    }
    
    func testFragmentationUnitAWith8Packets() throws {
        var p1 = try XCTUnwrap(BinaryReader(hexString: "7c8588840922628000821c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75"))
        var p2 = try XCTUnwrap(BinaryReader(hexString: "7c05d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d71dffff811ede787e03800130c5952dffb2a965552f2aa965552df1f800447eabfaffff8388505d75c76000936926db4936bfff80b981a8cb03f0008d9caf2c06a37fc03b08b7009d68543c2c24d1e07a0f03323849a3849a3f00093d372c788c57fa40183955c781a37052785a0467c08cb079f03b367fedb7343bfd71d8006b02157370c63daeb7ff011a48cd1b204651f3c68598fa3e031f80e175496ffa8f7c072dcbf0e15f2c33fdf3f1d800768d863a31ae2d857faff035b21c9e7f806d376cc25b81a3e9ebae3b0004934d000feff031f677fe01355e07bccae5e5572caae5bef8ec002337dd775ff806cbc41efc76000936909dffccceedfff80a94351b020598fa3e07e0011b30b4b6145967f811947cf23480ecf0954b634b700032c3e0396534b29a58fc001aa33ce8b0d0643ffc63d3d01a368a9e7f190e052c3b814b0869b48d8db68347d175c76000c591882fc6cb0835a67fe09bfe034d83e2b09601d845b8577b1bc7e525fe1c9f2c393e5f8727cb59de3b0005e70339ae8730aa67f9937361600bb3078646dcb9c1e7ae3b00087affabefffe023921aa3a0"))
        var p3 = try XCTUnwrap(BinaryReader(hexString: "7c05fc005ccd4f2200350417fc08e8f9e0d07634e8d843814b4c40ed812000cb21c0a587702963f0017a6e59a1238bff08cd7cbc0d19a149e3b0032fc21919a46c1d800466fbaeebffb54d0688e9febaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebae3b0017324cc03099a4907abdf89b3cf4d82b5d2cf838036ff43ccae2fc76fffb4d6d343b7f918918da6a461ad75d708e00170a91cb2142d97431f9408f5b6f568e667ed8e4f1f1b39e5404749877a605694db747b9555508601476956da47ffff0124d9246c21c0a742180041f5df777ffc0ec985ec7e11c01891961b8ddfd269088aaf6de6c30d20ee5ffdf6e65ce6b3b7edddb6c98be9bbec04f46ca8f043000b82e8b4a2b1d0f2ca3f811c8c6bedff0c4db678098cc1fa6f1f800233366c05fffc40c9900071a21b98f45f2bbc01d1e0b7e0f05a0f05bbebf77ebf7086002d965196651df7fe44c01ff60b58c11b02bb00514d39e0fc0042f5dc71fefdff0029da963653dfffe3b041f777e630524434fbdf011868c2975ffe027a36547a21a6982f4dff8ec00219af6d29b5fff02336f3d8a1b079e1d805dffc084999631007dcd6782e0da66abfc81402b9903015cfc77ffed6d343bffed35b4d0ec004665ece533bfff049fe40ea5303698238003d1a6114eca7e10a1b13805691998f40452668362eb97be9d9d9d3adb9de9def6767f847016244664437e7fff026fefbbe1ac0b4f0e360545e0218bffff8091b5d81dfe3b0004d2bc3388c8fb2c38500225a836737aff02a4c113c7eb4afc4c5b2cf792dcc12d378ec00152a5216639024961243e04c66c34e5999ad6f04c160d798f013bb7fe78fc780012085152cd298d3a285a0b77d7e9682d0742d7ebf7fc76002f489b48c99df7fe024b3248d8588119c08c985de9e3f0004464464c8c8c87d1ff88f97c1861f1c64f9be1876837ff1d80580067f8e631f0ac67c6469dc67f929e60969bfa2026bd67bf8470004d482a5c6528b64a54aaa0095a90dd3b60139506f57a050550475b7d5addfeaf02fa60d6b39e5554218051faafebfffff009b7f0fba1ac0b4f07600187a4e1ddf7fffffe6bc3e05467830f5d81d5f508e04c9b0b1790a249677fdeec03150689e9fbb70095d66122bd76eeef05bf568d6ecf7653f304af2ebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaeb8ec005e87bb0cfcd7b8f57bc02a958f3da4137036e3fc403e0f3de4e9f9e7bc21800bda6822dd08573e01937107a231e059ef9be809a681ba41e9cc3f00a39e559806a81cf058a0bf8a0b1417fdf4e6700c06d497cc07065869b07e1dcb7ff5fd75c76001083dc6031b275eef811959e7a9b81b71f100f81e7a4232dc086182fffff847000bd98d12508aa5584f7ce04699136cf032b5e83df6e0283c277763a098b777708e040fb5482ca3694d6fdc802667313a76cbcf2a0086b690fe9b95555861d079ee629779e3f1f800423dcd34dafe35fd8159e9d9ac83dff1d832da410b3bac7e7eff1199facf793bf8167be0466cf3c0c95c20445b8e8003733c00b11d80026b0e7d4833d30873fe1377eee063fa0257be685420f2178fc021a000e49200a7c0f8c1288682e7bd75973d0cbeb278fd5f5fff1d803212322640a4aa94786b40964745ed4a68753bffc0313530f44c340f3dfe3b00158d3210b9bec3d5ea2a8cf90e28770d58db172f049b8750ee43a8ee168131228e09acc76002e9a786445158fbdf900fb5d8220ed44df1ae049401a9433e16814077fffffe01133bbaf0fc003e4801e46d019fc0037809f01359e0c8a4207bf9bc09910099c239df30707a6a61f80f69cb7fe5054b282a5e506965054b1d8010fc03a8a0fcfbc07465b987465b9c0a02beb79d447c023a0e8cb730e8cb7301d286b84300ae1143836b0b404c043fffffde0483d67"))
        var p4 = try XCTUnwrap(BinaryReader(hexString: "7c058238005214d313e2640edc0263ffedcfc9452b1aba09779d83fbe01559eefb77bc23809667a131eab6106ca20cb0c4b64b4aded2a68779dfe7fc08455e7bd7886d663b000d55c6e2cc18daf861b1e7bc8422dc05e584d73c3a22dca3026fc0e88b7107c08f076002e44d900c2ee9041eaf4046958779d9b7c0d2c0ff188cad6605d7ef3dfe3b00059c464f0082ae94388fc0316c444f400db3759f50dcf28ef80b3df1834059ef1f813a6d3da699bfffa5a1e8e8f7e5a3d01b6c32797ff1d803e42998a566294f57b8081324747bfe56036b30c4b19f3f1d800f829ec02b52a31bef1908a3fd6799450019667bfe1239b324e0c53e320eb0ee61d116e63c0e03b00bbff844b6b10e8b7907bd9815cfcac0ae6560573f08e0015d8d721704442b93fce016efb57b93b482d59b01941bbedde866ea0169f2cf776eee11c08684bda9422699027fee620cb0cbc92f5ad5fcc33a1fa63f5555e422c6ca088e454c10c5fe519ad67bdffe3b06efcc4caacc7abdf00bcbcb3dff003e0b3de5a04c7d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d71d800b90bf439dd4821eaf408f7e7a2d2b0d33157362ae719c0d322101b4b9e62ae6c55cdf1fff01af5f079fff08e06c9b30319dbab1d0efc4ed0341afcfe30053c58d8c67ffe02a63093d781317967975c7601a0b576f9f4a5292915cf9422b9284571723b00680bc8e58f00b92b6b3c385bdcfc385bdcc38596e7e3b006c4f88e3dfd2781d6773e1c465b90e232dc5b8ecdc02448a55c0e5bb81e8ae070afb9f87a2b81c0bfb81e8ae0702fee7e3b00d54117e780617c41ec3cc2b9f87b0ae6510ae6b8ec036a33f9e144dff03895721c4ab9f8ecaa3ed6207fdcfc39fb9873bb98ec003b67388043e6b5defef0589edacf02903b6e7bf811d7e785a07ea1b64466b993938fc00eac10a943359a2da33d04326691b11143493d695ff03bcc6d1ebfe027c66547add698af38768e99f57730f6ee7ff872fb9872fb98ec07264699f7f0892c7c1d13103b0ae13c76038910d33a86d4cf30f2773f281b73281b731d82ca4cfc6fdac873bb9f0e1fee4387fb83bffc62e7f24dcc9373f1d8035570963dfdc4b0f8353b99511dcc9c760e0b95d30cf266403d95cfc3d95cc3d95c7c3c760850c817c195707b78790ae0f37f8790ae1c0bc3c8570e05ebb1d8d174dc7886ae61c1dae7e1c0144b98700144b9f8ec01b13e178f7c0b955e7a4016f73e1c2dee4385bdc5f8ec07a4930e2303cfb9f8727dcc393ee7ebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaeb8fc00131f2bf1af53ad70aeb5653b9f80fc4d7332815f3ffc7e000ce4def580a9c65e069a3f9e19027f9387f002c2c90d8075c814b0240cc970333fff8fc016d8aa620e4a141a21ff803eedae78367207fa367cddf08465961d0cb2e00911a09bfed29681d9efabd348fc0028f1cd34d1fffbf1afec0acf4ecec83dff5fae3b0120f4e3dfff80ab587a54477171d8037fd913648f57bafc0a2d37e60a025a8967e3b006279332af77e607a2b9ee1c89ae0055563cf10444b83bffffee3b021569b1cf7fb83a9e0145d0f3c402dae7c760039da9a6d6af7f2bfe122ceb0b9833e64e3b000827f933739781ff73f0c27e7905401b73bbf1d808fd71efebf03b57305405223598fc005ed86226dec29e66f52113dcfc09465cf20240acf3fff1f8004033d9a30ad27d73dc83c1f970068fe0b274044b31485a07bffc7e061941e51d89be16c7c2328e196c48bc091b9831f79683d6a9c43a8fff007b9a41b4d1e06c043ffbffe3b000efef3021b665caf600d93641ecc604df9fc6ac09accaa0ae60ecf80a82923598ec0085febe3d5eff1bb9f04bb69a42e0da65c760026ed4d4da79bf8ddcfc283edd70411da89b1d8008ad57f5ebfccff80c55352"))
        var p5 = try XCTUnwrap(BinaryReader(hexString: "7c051c16d70760937faffef80c4e33e7c760036ed26b323d5efe487c184ae614709bcd71d8026ef74da5fbde48781186cf3da42286c1e7b4878ec05944e65fe2c7cd001569878ba79098ee12846e271d8037fda26c91eaf384a073f73f0e057dcc0a81b29f3dfe3b000866bdb4a665fe57fc0c4d35902e0afa4cf2e3b085af8f763f81c1d2e61d14b9faebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaeb8ec0015152ca485252c293f81d196e7c35a0325912973cf0fc070002e084912dc69e9a6ed76b801452c05bb632c058a02c238002331e7dc3f2337a4c6a69810f25af213d3ed934f8d3e31cf96648e13e3415ae47180598ddde076001e7d9c5630817bb36597ff788cd8f3de6433660ecfbb80d30370ac4f7ef9bf57ddc2180026a1dfa310af5885fe0193e20f7c068ff0159e9a5220f0ec00126c926ccc891997ffff80492f60ef6c3f00067ea00ae9e855c2bfc06e03e1580e8cb2faeb1a8cb3b096e0d1f4afac760016e0f2cc19a9aa29b7be05caaf3d35829dacf804ac99857b6f89000f899e91112e0ec023ebbeefffff848b483fa6ff08e00e0a1077b11081b62fde1102b4cf77d81296625f677edde59ff7bf66a28786cefb00c68ddf38ec001cec65398821efc1342ddc137fc2789ff5acecaa81fe99eec08f7ca4498dcc7abec0be41192e5872325cb1f80026a0efd0863bd631fe10b1f60a03611ddf3681370123b9dc0a967876041b14bb168db3c4fffeec31e46dbc088c9726051ebcf7f61e325cec3c64b8256e81b4db524d0e8f78fc0012689ad19193c8ff012c9b0579d27b2312fb7ff08e02179de38dc12a05f1a7c69a69a6980442a86ce5d6d5e320356230135466fa157cfe78058ec00136c1fff9c6726d271c1239b13cbcb3c27a606bce08224b9fe7f5fb90449730e44973f1d8007b2931b8d328e6e71db82f9bfc900a48b9e35f187a06e6eb3d41d02258590363cb206c47e000a69c0feff050f9863387455e2ac5580516a79ef6cb901dbf8ff08e002cd6a83f744d9d3df26988e82a66093d269f1a69f1a6980b0c1a0cb16b8dc663b83f000a43ee4194d443f44bd7c093e06b58021d7f945bb7fe602b4dd803bffec2eb44f3c6b0065ed07da3b82d67effbfffff8092cd0af387600791e28629ed1a8f6476a317337197c0f19ae2a4e02845b7cf79283b9878cd7007be720f3c1e335c6949a0ef389a8ec002da1b02b6908d604a420009e4f151ef6db4c2f6dffe01a2a0d856bf022fd3c2aecdf3c1d8009c99dd45360b14f3f62811d7e7953160c9e15912799125730028fd28355780a0aa1e4ae61e4ae63b000364d4277ac23f7be172537ea20285243cf780a2e20f1703600896a4056ec5c0d81d8017c72628423a79e4ef65bf017228e967e0e007ebe87892e7081324747bc7e001d0a6f0e638d2d73cf12036167bfc04c4e650fc30ed06f8fc0013228d8347ec841bdbefa7dcfa011b2dbc6a989b250b816f80634672a611a844a1e29c79960fc760177ff0109332c715a8f6b5df8faff02cff160061120061f1d8003bf07227502762b45fffa0193e20f446f02cf787654f0c7811b5be4905e7801b66d2cf81178e2050838814076003c993a64664c8cfff01126a1de77b4ab40ef4dfe11c09246615acda470b9fa1ec098b6b3ceda7462f6ddbf6efdbb8138283c36f1df608bf7ce3b00047664315cc71ffc2e653c08ca6f3cc6b8d87d83b567af80466a0d57d00d5b6f9e02829d7c45e3b00168df222336447fff81202e120763e40bd30ec0041aa80cf2415a084ab4d829a06d57ee4006e6e4006e7ebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaebaef847003c9cc0219bf71a11f7ffe08c640c9e2700fc84b1afdd5c0200f6095cb3fc04ab42eea08600107a4ef4d3bffe773056c019e35cf3f843001f93c6469ab959"))
        var p6 = try XCTUnwrap(BinaryReader(hexString: "7c058bffe00ee6d53ce588296026a42c8d811c0012fc773bead4460e3f3f3f017fcf44d802a3e824ade1c01a3f85916061fc760009a21afc8dbbab6ff6095c87915cf80d94927e7a117c82b2200ec01f3c537aed3df7fff25cc177c116a5e07d995b00abc09065a1d803262fb76556ecaaa93dacc393ee7f13952d7be5c1b1f08e04b66c0433eeef4656f1a9464e8f73c805ef11507a55e5579550129f04a7d7acc567225145cf07600107a4e7a69bfff6b3605d3f04f8cbd9f086003f279914b33223fff8ccd62146493c37a05ac047000b4d879de5273180971f9f9f8941d2402514113c6ff87803b8f2437120d7bfbffe3f001f4cd34c8c8d118a38fe30122d107eda6667279ffc76024e3341263edcd15f6ff143a61bfe20311868a164c6b3ffe00fda05ec1100496e021afffeae6bf1f80031e345132baded3986fff007e6656c02af81417809bf3b6063e41318f4494929e7847000f9212a12ee72ff7e00b6dfafd8eec75f891536dfbf9fbfe37dfff847040e9688c6cb6467cbf7aaefb832c969349971c4cf14ac65736fe579556a9c4c99b1265a3673c8ec001e9ac88e1a2a3fffdfbbfc10905ec0923259e5f14bb086014734559b443ffff803f3314d8118f0164ffc08e000ea8e0876aae3c83008cdb6d9f9fc624848260316d098c7af00776fa57475099f6971ae7ff27e3b000452c5c2312ddef086444044b243bcef3331c9e0d7aef37ff31e388dedf372d31474c033c05ec0ec0041f7777feeffeef8370c96e1b779f8430004e4f199a6ae7331fffc01f9995b2048f5281540b05e201953c08e0017e35976f09a1bbfc7e0659eecfc4f244bed43fe9fbfc70c44d9bfdfff1f800b1ab290a4179cd60bf04b20d7dbfc018a8f8456aebff8ec002f16613eaed8d2965affe0185c138ad78099342e8d99dcc17b00679ae7810dfffff8216b60fc003db308dc9c7f1483fedfc017fcc84db607fe5581391261b8010af091f42c713b9656e58ec0192492480187aaa2cb6f16144f7df2111ee7e1d11ee61d11ee7e11c0d1d2f118d896c8c4d7ff72020592747960031355cac66e6dfcaf2aadf389a286c5afce6ef6a3b000c3c88ec8c98ffefff033f017960bc36b8754238051da55b693ffff803f332b605502c17808e002c9d856f6d690403891f9f9fa17680482724137b74a22a2f00bedefbb44c45240d53cffe4f5d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75df7efbefbfdf7dfefbebbefdfbefbf7dfaefbf7df7df7dfbf7dfefbfdf5d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d"))
        var p7 = try XCTUnwrap(BinaryReader(hexString: "7c0575d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d"))
        var p8 = try XCTUnwrap(BinaryReader(hexString: "7c4575d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d75d78"))
        
        var parser = H264.NALNonInterleavedPacketParser<[UInt8]>()
        XCTAssertEqual(try parser.readPackage(from: &p1), [])
        XCTAssertEqual(try parser.readPackage(from: &p2), [])
        XCTAssertEqual(try parser.readPackage(from: &p3), [])
        XCTAssertEqual(try parser.readPackage(from: &p4), [])
        XCTAssertEqual(try parser.readPackage(from: &p5), [])
        XCTAssertEqual(try parser.readPackage(from: &p6), [])
        XCTAssertEqual(try parser.readPackage(from: &p7), [])
        
        let nalus = try parser.readPackage(from: &p8)
        XCTAssertEqual(nalus.count, 1)
        let nalu = try XCTUnwrap(nalus.first)
        
        XCTAssertEqual(nalu.header.type.rawValue, 5) // Coded slice of IDR picture
        
        let expectedNaluPayload = [
            // Packet 1 -- start
            p1.bytesStore.dropFirst(2),
            // Packet 2
            p2.bytesStore.dropFirst(2),
            // Packet 3
            p3.bytesStore.dropFirst(2),
            // Packet 4
            p4.bytesStore.dropFirst(2),
            // Packet 5
            p5.bytesStore.dropFirst(2),
            // Packet 6
            p6.bytesStore.dropFirst(2),
            // Packet 7
            p7.bytesStore.dropFirst(2),
            // Packet 8 -- end
            p8.bytesStore.dropFirst(2),
        ].flatMap({ $0 })
        
        XCTAssertEqual(Array(nalu.payload), expectedNaluPayload)
    }
    
    func testFragmentationUnitHeaderReadAndWrite() throws {
        let header = FragmentationUnitHeader(
            isStart: false,
            isEnd: true,
            reservedBit: false,
            type: .fragmentationUnitA)
        var writer = BinaryWriter()
        try header.write(to: &writer)
        var reader = BinaryReader(bytes: writer.bytesStore)
        
        let parsedHeader = try FragmentationUnitHeader(from: &reader)
        XCTAssertEqual(header, parsedHeader)
        XCTAssertTrue(reader.isEmpty)
    }
}
