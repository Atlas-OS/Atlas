@{
    Name        = 'Remove ''Edit with Paint 3D'' from Context Menu'
    Description = 'Removes ''Edit with Paint 3D'' from context menu'
    Registry    = @(
        @{ Path = 'HKCR\SystemFileAssociations\.3mf\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.bmp\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.fbx\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.gif\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.jfif\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.jpe\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.jpeg\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.jpg\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.png\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.tif\Shell\3D Edit'; Operation = 'DeleteKey' }
        @{ Path = 'HKCR\SystemFileAssociations\.tiff\Shell\3D Edit'; Operation = 'DeleteKey' }
    )
}
