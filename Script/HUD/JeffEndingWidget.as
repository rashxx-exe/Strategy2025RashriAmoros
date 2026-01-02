class UJeffEndingW : UUserWidget
{
    UPROPERTY(meta=(BindWidget))
    UTextBlock Txt_Result;

    UPROPERTY(meta=(BindWidget))
    UButton Btn_Play;

    bool bPlayerWon;

    UFUNCTION(BlueprintOverride)
    void OnInitialized()
    {
        if (bPlayerWon)
        {
            FString WinText = ("Muy bien has ganado.");
            Txt_Result.SetText(FText::FromString("" + WinText));
        }
        else if (!bPlayerWon)
        {
            FString LoseText = ("Que tonto has perdido.");
            Txt_Result.SetText(FText::FromString("" + LoseText));
        }

        if (Btn_Play != nullptr)
        {
            Btn_Play.OnClicked.AddUFunction(this, n"OnRestartClicked");
        }
    }

    UFUNCTION()
    private void OnRestartClicked()
    {
        Gameplay::OpenLevel(n"Main");
    }
}