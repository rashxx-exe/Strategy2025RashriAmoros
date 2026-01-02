class UJeffsPlayingCard : UUserWidget
{
    UPROPERTY(meta=(BindWidget))
    UBorder Border_Color;

    UPROPERTY(meta=(BindWidget))
    UImage Img_Jeff;

    UPROPERTY(meta=(BindWidget))
    UTextBlock Txt_Name;

    UPROPERTY(meta=(BindWidget))
    UProgressBar Vida_Bar;

    UPROPERTY(meta=(BindWidget))
    UTextBlock Txt_Vida;

    UPROPERTY(meta=(BindWidget))
    UTextBlock Txt_Hab;

    UPROPERTY(meta=(BindWidget))
    UTextBlock Txt_Attk;

    AJeff LinkedJeff;

    UMainW MainWidget;

    void CreateCard(AJeff Jeff)
    {
        LinkedJeff = Jeff;
        Jeff.JeffPlayingCardBP = this;

        Txt_Name.SetText(FText::FromName(Jeff.JeffName));
        Img_Jeff.SetBrushFromTexture(Jeff.JeffIcon);

        if (Jeff.Team == EJeffTeam::Player)
            Border_Color.SetBrushColor(FLinearColor(0.5, 0.95, 1.0, 1.0));
        else if (Jeff.Team == EJeffTeam::Enemy)
            Border_Color.SetBrushColor(FLinearColor(1.0, 0.7, 0.7, 1.0));

        if (Jeff.TypeJeff == EJeffsType::Calabaza)
            Txt_Hab.SetText(FText::FromString("Tanque"));
        else if (Jeff.TypeJeff == EJeffsType::Basico)
            Txt_Hab.SetText(FText::FromString("Basico"));
        else if (Jeff.TypeJeff == EJeffsType::Delfin)
            Txt_Hab.SetText(FText::FromString("Distancia"));
        else if (Jeff.TypeJeff == EJeffsType::Venom)
            Txt_Hab.SetText(FText::FromString("Ataque"));
        else if (Jeff.TypeJeff == EJeffsType::Playero)
            Txt_Hab.SetText(FText::FromString("Curación"));
        else if (Jeff.TypeJeff == EJeffsType::Bezos)
            Txt_Hab.SetText(FText::FromString("Potenciador"));
        
        UpdateLife(Jeff.Vida, Jeff.MaxVida);
        UpdateAttack(Jeff.AtaqueBase);
    }

    void UpdateLife(int Vida, int MaxVida)
    {
        float percent = float(LinkedJeff.Vida) / float(LinkedJeff.MaxVida);
        Vida_Bar.SetPercent(percent);

        FString VidaTxt = "" + Vida + " / " + MaxVida;
        Txt_Vida.SetText(FText::FromString(VidaTxt));
    }

    void UpdateAttack(int Ataque)
    {
        FString AtaqueTxt = "" + Ataque;
        Txt_Attk.SetText(FText::FromString("" + Ataque));
    }
}