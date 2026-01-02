class USettingsWidget : UUserWidget
{
    UPROPERTY(meta=(BindWidget))
    UCheckBox CameraFixed;

    UPROPERTY(meta=(BindWidget))
    UButton Btn_Back;

    UFUNCTION(BlueprintOverride)
    void OnInitialized()
    {
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());
        if (gs == nullptr) return;    

        if (CameraFixed != nullptr)
        {
            CameraFixed.OnCheckStateChanged.AddUFunction(this, n"OnCheckBox");
        }
        if (Btn_Back != nullptr)
        {
            Btn_Back.OnClicked.AddUFunction(this, n"OnExitClicked");
        }
    }

    UFUNCTION()
    private void OnExitClicked()
    {
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());
        if (gs == nullptr) return;

        auto hud = GetMainHUD();
        if (hud != nullptr)
        {
            gs.isMenuOpen = true;
            gs.isSettingsOpen = false;
            hud.ChangeMenu();
        }
    }

    UFUNCTION()
    void OnCheckBox(bool bIsChecked)
    {
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());
        if (gs == nullptr) return;
        gs.isCameraFix = bIsChecked;
    }

    AMainHUD GetMainHUD()
    {
        auto pc = GetOwningPlayer();
        if (pc == nullptr)
            return nullptr;

        return Cast<AMainHUD>(pc.GetHUD());
    }
}