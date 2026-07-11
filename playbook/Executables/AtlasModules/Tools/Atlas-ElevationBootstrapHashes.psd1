@{
    SchemaVersion = 3
    Source        = 'tools/native/Atlas.ElevationBootstrap'
    Build         = @{
        Runtime         = 'none'
        Reproducibility = 'Two independent unsigned builds compared byte-for-byte per architecture'
    }
    Toolchain     = @{
        ClangCl = @{
            FileName = 'clang-cl.exe'
            Length   = 104745472
            SHA256   = '986AF49C2D1EEFEAC324F724FF54597753D1053927FA5D58A37A457F578E1CF8'
            Version  = 'clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)'
        }
        LldLink = @{
            FileName = 'lld-link.exe'
            Length   = 71456768
            SHA256   = '72DE1900946337ABA56616B14713A2EFA293ECDF54B945A9D7D0F6676C3B9ECD'
            Version  = 'LLD 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)'
        }
        ClangResourceDirectory = @{
            RelativePath = 'lib/clang/22/include'
            Version      = '22'
            FileCount    = 301
            SHA256       = 'CFD889774A8B67794268C29C43C235E418759103362168A0C7714B3A31ECB253'
        }
        MsvcCompiler = @{
            FileName = 'cl.exe'
            Length   = 893328
            SHA256   = 'DC8426B8760D92CF757DF3D10B9F0244A95B454FF43194A58161568A0EC70D53'
            Version  = '14.51.36248.0'
        }
        MsvcTools  = '14.51.36231'
        WindowsSdk = '10.0.26100.0'
        IncludeDirectories = @{
            Msvc = @{
                RelativePath = 'VC/Tools/MSVC/14.51.36231/include'
                Version      = '14.51.36231'
                FileCount    = 353
                SHA256       = '1C6390382FFBDF78E16A737B7660EA91C399CA75ABA9FC7097F05391607105FB'
            }
            WindowsSdkUcrt = @{
                RelativePath = 'Include/10.0.26100.0/ucrt'
                Version      = '10.0.26100.0'
                FileCount    = 66
                SHA256       = '6F00A3BEC905E7EEC0CE208BDFB85A8EED8A1F3157140D24CF57CF2855C7B2C0'
            }
            WindowsSdkShared = @{
                RelativePath = 'Include/10.0.26100.0/shared'
                Version      = '10.0.26100.0'
                FileCount    = 303
                SHA256       = 'E4FE166C57E3BBDE3BBF56D932D6140A54243EE4B48412C510815B55E4042965'
            }
            WindowsSdkUm = @{
                RelativePath = 'Include/10.0.26100.0/um'
                Version      = '10.0.26100.0'
                FileCount    = 2189
                SHA256       = '7B51B218649758D74611DC64EA5483F2741B92B135669DE6259A3C0DB990922B'
            }
        }
        ResourceCompiler = @{
            FileName = 'rc.exe'
            Length   = 55736
            SHA256   = '65DB0D7B4F10BA0F55973FD9356543A556DA9EC1C777A0C05F05A0329C8A100A'
            Version  = '10.0.26100.8249'
        }
        ResourceCompilerDependencies = @{
            'RCDLL.dll' = @{
                FileName = 'RCDLL.dll'
                Length   = 264616
                SHA256   = 'CF9EA3DDF9D2576962FE373A04244F044D7F287D6F247C5A08E6459BCADCE14F'
            }
            'ServicingCommon.dll' = @{
                FileName = 'ServicingCommon.dll'
                Length   = 1018280
                SHA256   = '6B0F33FC05B76882D86DAA33CC5D21B15276650ACC584A467778D27A7B5CDAC3'
            }
        }
        Libraries = @{
            amd64 = @{
                'BufferOverflowU.lib' = @{
                    FileName = 'BufferOverflowU.lib'
                    Length   = 385812
                    SHA256   = '5792B454FABBB01C0284425D9A2B4F7BAB24859BB9B8A08611618BCB35FAFD9A'
                }
                'kernel32.lib' = @{
                    FileName = 'kernel32.lib'
                    Length   = 311908
                    SHA256   = '341C7D56125A03B458E4D5093E4C79B33123CCFDFD610FE236937B8E6F3134BB'
                }
                'advapi32.lib' = @{
                    FileName = 'advapi32.lib'
                    Length   = 178306
                    SHA256   = 'ECAFE89A632A35B183C2129D2D8612B31A4D43A9CDA78C4B2E3BC6B130AE3C6F'
                }
                'bcrypt.lib' = @{
                    FileName = 'bcrypt.lib'
                    Length   = 14576
                    SHA256   = '9FE31DF255D17B0339391FF80A71BF2C5D442CC301BD2FE6EEEA00B626F10785'
                }
                'shell32.lib' = @{
                    FileName = 'shell32.lib'
                    Length   = 271926
                    SHA256   = '83B3D1B2C80F0F83A859470AE52D4CA2B582B9236C4D3AB99405A2178257FDFF'
                }
            }
            arm64 = @{
                'BufferOverflowU.lib' = @{
                    FileName = 'BufferOverflowU.lib'
                    Length   = 736750
                    SHA256   = '0E3993A1A5B919BD08EAAA2BCEB22B68124F015E8174B4BC44B956F60381A9AA'
                }
                'kernel32.lib' = @{
                    FileName = 'kernel32.lib'
                    Length   = 652320
                    SHA256   = '5A4A1E63AD1692F0767DC911D608E981E6E7B24B3EC2684429A61ADD648327F4'
                }
                'advapi32.lib' = @{
                    FileName = 'advapi32.lib'
                    Length   = 372828
                    SHA256   = 'E791CA5B5757B2DA9DE50F1EB5D795E5B3F455302932BB92894D9A15AA6BB689'
                }
                'bcrypt.lib' = @{
                    FileName = 'bcrypt.lib'
                    Length   = 29124
                    SHA256   = '66FDE77FDF81AA19806ECD5C34A8BEE92FB0DEA55AFF38F8106D1A1322DDC41F'
                }
                'shell32.lib' = @{
                    FileName = 'shell32.lib'
                    Length   = 625762
                    SHA256   = '0B5A546ECB9A68DDAC7F94789CD7944A0E8D6A6B49255AA76D75B7CA483E6BD2'
                }
            }
        }
    }
    Harness       = @{
        Requested             = $true
        BuiltArchitectures    = @(
            'amd64'
            'arm64'
        )
        HostArchitecture      = 'amd64'
        ExecutedArchitectures = @(
            'amd64'
        )
        Passed                = $true
        TimeoutMilliseconds   = 30000
    }
    Inputs        = @{
        'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.cpp' = @{
            Length = 126148
            SHA256 = 'F6090E9AF34899A8C7BD4C4EA2F9BDF67972AA15FAB81206626E62B88B6F682F'
        }
        'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.rc' = @{
            Length = 950
            SHA256 = 'BC7273E8CAB8A37A5C4888A1AECDBE48798A6E72E431998A09DE5E094DA5F3E8'
        }
        'tools/native/Atlas.ElevationBootstrap/Atlas.ElevationBootstrap.manifest' = @{
            Length = 1114
            SHA256 = 'FB1BF5167FF3FD3AF7F857A8FF9DB2F28B74F900C84D82586A0834CE7672B70F'
        }
        'tools/native/Atlas.ElevationBootstrap/resource.h' = @{
            Length = 63
            SHA256 = '4A3F7190028D944DBDACC539AAFC8B6BE9B714CD51418BE66419C681CAE64590'
        }
        'tools/build/Build-AtlasElevationBootstrap.ps1' = @{
            Length = 83445
            SHA256 = 'E221F73DA45B286AC7EABEEDC0877E0BD143523775D9CEF2537478C589C81ADD'
        }
        'tools/build/Test-AtlasElevationBootstrap.ps1' = @{
            Length = 105706
            SHA256 = '595A91E02668EB2B1EFB6B1B99645CB8F318B52D4508FA8B97C4FC85F8D0E409'
        }
    }
    Artifacts     = @{
        'AtlasElevationBootstrap-amd64.exe' = @{
            Architecture = 'amd64'
            Machine      = 0x8664
            Length       = 53760
            SHA256       = 'B8800ED869C3D8E4FEFC1070876356C6039700DD0629142B5F502CE71E332421'
        }
        'AtlasElevationBootstrap-arm64.exe' = @{
            Architecture = 'arm64'
            Machine      = 0xAA64
            Length       = 47616
            SHA256       = 'FCD8E3B37AAEA71582FB6910FD69F440BD99A3E374F23768B784D7EAB31EBF7A'
        }
    }
}
