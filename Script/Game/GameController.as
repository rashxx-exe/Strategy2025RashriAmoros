class AGameController : APlayerController
{
    default bEnableClickEvents = true;
    default bEnableMouseOverEvents = true;
    default bShowMouseCursor = true;

    UPROPERTY(DefaultComponent)
    UJeffsGameInputs Input;

    UPROPERTY(BlueprintReadOnly)
    AJeff SelectedJeff;

    ACamera Camera;

    AMainHUD MainHUD;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Camera = Cast<ACamera>(GetControlledPawn());
        MainHUD = Cast<AMainHUD>(GetHUD());
    }
}