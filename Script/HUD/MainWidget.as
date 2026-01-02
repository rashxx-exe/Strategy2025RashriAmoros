class UMainW : UUserWidget
{
    UPROPERTY(meta = (BindWidget))
    USelectWidget SelectWidget;

    UPROPERTY(meta = (BindWidget))
    UVerticalBox PlayerBox;

    UPROPERTY(meta = (BindWidget))
    UVerticalBox EnemyBox;

    UPROPERTY(EditAnywhere)
    TSubclassOf<UJeffsPlayingCard> CardClass;

    UPROPERTY(meta = (BindWidget))
    UTextBlock Txt_Pts;

    UPROPERTY(meta = (BindWidget))
    UButton Btn_NextTurn;

    UPROPERTY(meta = (BindWidget))
    UTextBlock Txt_Moves;

    void AddJeffCard(AJeff Jeff)
    {
        APlayerController pc = GetWorld().GameInstance.GetFirstLocalPlayerController();
        UJeffsPlayingCard Card = Cast<UJeffsPlayingCard>(WidgetBlueprint::CreateWidget(CardClass, pc));

        Card.CreateCard(Jeff);
        Jeff.JeffPlayingCardBP = Card;
        Card.LinkedJeff = Jeff;

        UPanelSlot panelSlot = nullptr;

        if (Jeff.Team == EJeffTeam::Player)
            panelSlot = PlayerBox.AddChild(Card);
        else if (Jeff.Team == EJeffTeam::Enemy)
            panelSlot = EnemyBox.AddChild(Card);

        UVerticalBoxSlot slot = Cast<UVerticalBoxSlot>(panelSlot);
        if (slot != nullptr)
            slot.SetPadding(FMargin(0, 10, 0, 10));
    }

    void ChangePoints(int Points)
    {
        FString PointsText = ("" + Points);
        Txt_Pts.SetText(FText::FromString("" + PointsText));
    }

    UFUNCTION(BlueprintOverride)
    void OnInitialized()
    {
        if (Btn_NextTurn != nullptr)
        {
            Btn_NextTurn.OnClicked.AddUFunction(this, n"OnButtonClicked");
        }

        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());
        ChangePoints(gs.PPoints);
    }

    UFUNCTION()
    void OnButtonClicked()
    {
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());
        gs.bisPlayerTurn = false;
		for (AJeff je : gs.EnemyJeffs)
		{	
			je.jeffUsed = false;
		}
		gs.EnemyTurn();
    }

    UFUNCTION()
    void UpdateMoves(int moves)
    {
        FString MovesText = ("" + moves);
        Txt_Moves.SetText(FText::FromString("" + MovesText));
    }
}