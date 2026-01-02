class UJeffCard :UUserWidget
{
    UPROPERTY(meta=(BindWidget))
    UImage Img_Jeff;

    UPROPERTY(meta=(BindWidget))
    UTextBlock Txt_Name;

    UPROPERTY(meta=(BindWidget))
    UTextBlock Txt_Vida;

    UPROPERTY(meta=(BindWidget))
    UTextBlock Txt_Dmg;

    UPROPERTY(meta=(BindWidget))
    UButton Btn;

    FJeffsData JeffsData;

    UPROPERTY()
    UMainW MainWidget;

    UFUNCTION(BlueprintOverride)
    void OnInitialized()
    {
        if (Btn != nullptr)
        {
            Btn.OnClicked.AddUFunction(this, n"OnCardClicked");
        }
    }

    UFUNCTION()
    void OnCardClicked()
    {
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());
        if (gs == nullptr) return;
        if (gs.PPoints <= 1) return;

        gs.SpawningJeff(JeffsData);

        auto hud = GetMainHUD();

        if (hud != nullptr)
        {
            hud.MainWidget.SelectWidget.SpawnRandomCards();
        }
    }

    UFUNCTION()
    void IntFromJeffStruct(const FJeffsData JeffData)
    {
        JeffsData = JeffData;
        if (Img_Jeff != nullptr && JeffData.JeffsImg != nullptr)
            Img_Jeff.SetBrushFromTexture(JeffData.JeffsImg);

        if (Txt_Name != nullptr)
            Txt_Name.SetText(FText::FromName(JeffData.JeffsName));

        if (Txt_Vida != nullptr)
            Txt_Vida.SetText(FText::FromString("" + JeffData.JeffsVida));

        if (Txt_Dmg != nullptr)
            Txt_Dmg.SetText(FText::FromString("" + JeffData.JeffsAtaque));
    }

    AMainHUD GetMainHUD()
    {
        auto pc = GetOwningPlayer();
        if (pc == nullptr)
            return nullptr;

        return Cast<AMainHUD>(pc.GetHUD());
    }
}