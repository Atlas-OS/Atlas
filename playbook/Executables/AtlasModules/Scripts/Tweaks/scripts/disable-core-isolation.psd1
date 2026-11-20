@{
    Name        = 'Disable Virtualization-Based Security'
    Description = 'Turns off Virtualisation-Based Security and Memory Integrity through Microsoft''s documented registry controls. Credential Guard, LSA protection, kernel stack protection and optional Windows features stay as they are.'
    Option      = 'disable-core-isolation'
    Script      = 'disable-core-isolation.ps1'
}
