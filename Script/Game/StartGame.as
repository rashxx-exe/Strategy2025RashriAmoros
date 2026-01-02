class AStartGame : AActor
{
    UPROPERTY()
    TArray<TSubclassOf<AJeff>> Jeffs;

    AMainHUD MainHUD;

    UPROPERTY()
    APlacePlatforms PlacePlatforms;

    float Time = 0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        APlayerController pc = GetWorld().GameInstance.GetFirstLocalPlayerController();

		MainHUD = Cast<AMainHUD>(pc.GetHUD());
        MainHUD.StartingGame();
    } 
}