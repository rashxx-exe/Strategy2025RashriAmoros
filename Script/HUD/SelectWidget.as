class USelectWidget : UUserWidget
{
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    UDataTable JeffData;

    UPROPERTY(meta = (BindWidget))
    UUniformGridPanel CardContainer;

    UPROPERTY()
    UMainW MainWidget;

    UPROPERTY(EditAnywhere)
    TSubclassOf<UJeffCard> CardsWidget;

    UFUNCTION(BlueprintOverride)
    void OnInitialized()
    {
        SpawnRandomCards();
    }

    UFUNCTION()
    void AddCard()
    {

        CardContainer.ClearChildren();
        
        TArray<FJeffsData> AllJeffs;
        TArray<FName> RowNames = JeffData.GetRowNames();

        APlayerController pc = GetWorld().GameInstance.GetFirstLocalPlayerController();

        int32 Column = 0;
        const int32 MaxColumns = 3;

        for (FName RowName : RowNames)
        {
            if (Column >= MaxColumns) break;

            FJeffsData Jeff;
            if (!JeffData.FindRow(RowName, Jeff))
            {
                Column++;
                continue;
            }

            UJeffCard Card = Cast<UJeffCard>(WidgetBlueprint::CreateWidget(CardsWidget, pc));

            Card.IntFromJeffStruct(Jeff);

            Card.MainWidget = MainWidget;

            CardContainer.AddChildToUniformGrid(Card, 0 , Column);

            Column++;
        }
    }

    UFUNCTION()
    void SpawnRandomCards()
    {
        CardContainer.ClearChildren();

        TArray<FJeffsData> AllJeffs;
        TArray<FName> RowNames = JeffData.GetRowNames();

        APlayerController pc = GetWorld().GameInstance.GetFirstLocalPlayerController();

        for (int i = 0; i < RowNames.Num(); i++)
        {
            FJeffsData Jeff;
            if (JeffData.FindRow(RowNames[i], Jeff))
            {
                AllJeffs.Insert(Jeff);
            }
        }

        if (AllJeffs.Num() == 0) return;

        int NumCards = Math::Min(3, AllJeffs.Num());

        TArray<int> SelectedIndices;
        while (SelectedIndices.Num() < NumCards)
        {
            int RandIndex = Math::RandRange(0, AllJeffs.Num() - 1);
            if (!SelectedIndices.Contains(RandIndex))
            {
                SelectedIndices.Insert(RandIndex);
            }
        }
        APlayerController PC = GetOwningPlayer();
        int Column = 0;

        for (int i = 0; i < SelectedIndices.Num(); i++)
        {
            FJeffsData Jeff = AllJeffs[SelectedIndices[i]];

            UJeffCard Card = Cast<UJeffCard>(WidgetBlueprint::CreateWidget(CardsWidget, pc));

            Card.IntFromJeffStruct(Jeff);

            CardContainer.AddChildToUniformGrid(Card, 0 , Column);

            Column++;

        }
    }
}