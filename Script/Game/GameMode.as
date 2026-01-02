class AJeffsGameMode : AGameModeBase
{
    AJeffsGameMode()
    {
        DefaultPawnClass = ACamera::StaticClass();
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        APlayerController pc = GetWorld().GetGameInstance().GetFirstLocalPlayerController();
        if (pc != nullptr)
        {
            pc.bShowMouseCursor = true;
            pc.bEnableClickEvents = true;
            pc.bEnableMouseOverEvents = true;
        }
    }
}