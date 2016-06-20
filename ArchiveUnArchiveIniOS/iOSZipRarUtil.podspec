

Pod::Spec.new do |s|



  s.name         = "iOSZipRarUtil"
  s.version      = "1.0.0"
  s.summary      = "A一个zip&rar 压缩、解压缩的工具类 iOSZipRarUtil."
  s.description  = <<-DESC
 *  1、rar文件解压缩；
 *  2、zip文件解压缩；
 *  3、判断压缩文件是否有密码；
 *  4、校验密码的正确性；
 *  5、将压缩文件重新压缩为zip完美解决iOS7和iOS8对zip文件预览支持的差异性；
 *  6、解压、压缩文件名编码解析；
 *  6、解压、压缩文本文件重新编码支持ios系统的预览；
                   DESC

  s.homepage     = "https://github.com/ceekay1991/iOSZipRarUtil"
  s.screenshots  = "https://raw.githubusercontent.com/ceekay1991/iOSZipRarUtil/pod/ArchiveUnArchiveIniOS/screenShoot/1.png", "https://raw.githubusercontent.com/ceekay1991/iOSZipRarUtil/pod/ArchiveUnArchiveIniOS/screenShoot/2.png","https://raw.githubusercontent.com/ceekay1991/iOSZipRarUtil/pod/ArchiveUnArchiveIniOS/screenShoot/3.png"
  s.author        = { "ceekay1991" => "ceekay0415@gmail.com" }
  s.platform     = :ios
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/ceekay1991/iOSZipRarUtil.git", :tag => "#{s.version}" }
  s.source_files  = "Class/**/*.{h,m}","ThirdParty/unchardet"
  s.public_header_files = "Class/**/*.h"
  s.framework  = 'Foundation','MobileCoreServices','SystemConfiguration'
  s.requires_arc = true
  s.dependency 'UnrarKit', '~> 2.7.1'
  s.dependency 'zipzap', '~> 8.0'
  s.dependency 'ZipArchiveFork', '~> 1.3.0'

end
