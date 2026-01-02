class AMainHUD : AHUD
{
    // 	SETTINGS //
// ------------------- //
// 	PROPERTIES //

    // 	CLASES WIDGETS //
        UPROPERTY()
        TSubclassOf<UMainW> MainWidgetClass;
        UPROPERTY()
        TSubclassOf<UMenuWidget> MenuWidgetClass;
        UPROPERTY()
        TSubclassOf<USettingsWidget> SettingsWidgetClass;
        UPROPERTY()
        TSubclassOf<UJeffEndingW> JeffEndingClass;
    // ------------------- //

    // 	WIDGETS //
    UMainW MainWidget;
    UMenuWidget MenuWidget;
    USettingsWidget SettingsWidget;
    UJeffEndingW JeffEndingWidget;

    // ------------------- //

    APlayerController MenuController;
// ------------------- //

    UFUNCTION()
    void StartingGame()
    {
        MenuController = GetOwningPlayerController();
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());

        MainWidget = Cast<UMainW>(WidgetBlueprint::CreateWidget(MainWidgetClass, MenuController));
        MainWidget.AddToViewport();
        MenuWidget = Cast<UMenuWidget>(WidgetBlueprint::CreateWidget(MenuWidgetClass, MenuController));
        MenuWidget.AddToViewport();
        gs.isMenuOpen = true;
        SettingsWidget = Cast<USettingsWidget>(WidgetBlueprint::CreateWidget(SettingsWidgetClass, MenuController));
        SettingsWidget.AddToViewport();
        JeffEndingWidget = Cast<UJeffEndingW>(WidgetBlueprint::CreateWidget(JeffEndingClass, MenuController));
        JeffEndingWidget.AddToViewport();
        ChangeMenu();

        MainWidget.SelectWidget.MainWidget = MainWidget;
    }

    UFUNCTION()
    void ChangeMenu()
    {
        MenuController = GetOwningPlayerController();
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());

        if (gs.isSelectOpen)
        {
            MainWidget.SetVisibility(ESlateVisibility::Visible);
        }
        else if (!gs.isSelectOpen)
        {
            MainWidget.SetVisibility(ESlateVisibility::Hidden);
        }
        if (gs.isMenuOpen)
        {
            MenuWidget.SetVisibility(ESlateVisibility::Visible);
        }
        else if (!gs.isMenuOpen)
        {
            MenuWidget.SetVisibility(ESlateVisibility::Hidden);
        }
        if (gs.isSettingsOpen)
        {
            SettingsWidget.SetVisibility(ESlateVisibility::Visible);
        }
        else if (!gs.isSettingsOpen)
        {
            SettingsWidget.SetVisibility(ESlateVisibility::Hidden);
        }
        if (gs.isEndingOpen)
        {
            JeffEndingWidget.SetVisibility(ESlateVisibility::Visible);
        }
        else if (!gs.isEndingOpen)
        {
            JeffEndingWidget.SetVisibility(ESlateVisibility::Hidden);
        }
    }
}