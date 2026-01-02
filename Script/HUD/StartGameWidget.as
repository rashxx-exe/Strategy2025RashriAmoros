class UMenuWidget : UUserWidget
{
    UPROPERTY(meta=(BindWidget))
    UButton Start;

    UPROPERTY(meta=(BindWidget))
    UButton Options;

    UPROPERTY(meta=(BindWidget))
    UButton Quit;

    UPROPERTY()
    TSubclassOf<AMainHUD> HUD;

    AMainHUD MainHUD;
    
    UFUNCTION(BlueprintOverride)
    void OnInitialized()
    {
        if (Start != nullptr)
        {
            Start.OnClicked.AddUFunction(this, n"OnStartClicked");
        }

        if (Options != nullptr)
        {
            Options.OnClicked.AddUFunction(this, n"OnOptionsClicked");
        }

        if (Quit != nullptr)
        {
            Quit.OnClicked.AddUFunction(this, n"OnQuitClicked");
        }
    }

    UFUNCTION()
    private void OnStartClicked()
    {
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());
        if (!gs.GameStart)
        {
            gs.GamePaused = false;
            gs.GameStart = true;
            gs.SpawnEnemiesJeffs(true);
        }
        else if (gs.GameStart)
        {
            gs.GamePaused = false;
        }
        
        auto hud = GetMainHUD();
        if (hud != nullptr)
        {
            gs.isSelectOpen = true;
            gs.isMenuOpen = false;
            hud.ChangeMenu();
        }
        
    }

    UFUNCTION()
    private void OnOptionsClicked()
    {
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());

        auto hud = GetMainHUD();

        if (hud != nullptr)
        {
            gs.isSettingsOpen = true;
            gs.isMenuOpen = false;
            hud.ChangeMenu();
        }
    }

    UFUNCTION()
    private void OnQuitClicked()
    {

    }

    AMainHUD GetMainHUD()
    {
        auto pc = GetOwningPlayer();
        if (pc == nullptr)
            return nullptr;

        return Cast<AMainHUD>(pc.GetHUD());
    }
}