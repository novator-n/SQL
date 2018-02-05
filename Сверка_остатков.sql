USE ukopen_qort_db
go
drop table #qort_pos
drop table #quik_pos
go
-- Сверка остатков в T0
DECLARE @T_dur as Varchar(5) ='T0'

-- запрос по остаткам QORT

SELECT
	P.[id]
	,P.[Subacc_ID]
	,SA.[SubAccCode] as Subacc_SubAccCode
	,SA.[IsAnalytic] as Subacc_IsAnalytic
	,SA.[SubaccName] as Subacc_SubaccName
	,SA.[TradeCode] as Subacc_TradeCode
	,P.[Account_ID]
	,A.[Name] as Account_Name
	,A.[AssetType] as Account_AssetType
	,A.[TradeCOde] as Account_TradeCOde
	,P.[Asset_ID]
	,S.[ShortName]
	,S.[SecCode]
	,P.[VolFree]
	,P.[created_date]
	,P.[modified_date]
INTO
	#qort_pos
FROM
	[uk-sql1].[ukopen_qort_db].[dbo].[Position] as P
	LEFT JOIN [uk-sql1].[ukopen_qort_db].[dbo].[Subaccs] as SA ON P.[Subacc_ID]=SA.id
	LEFT JOIN [uk-sql1].[ukopen_qort_db].[dbo].[Accounts] as A ON P.[Account_ID]=A.id
	LEFT JOIN [uk-sql1].[ukopen_qort_db].[dbo].[Securities] as S ON (P.[Asset_ID]=S.[Asset_ID] AND A.[AssetType]=1) 

SELECT * FROM #qort_pos --WHERE Subacc_TradeCode='2612'
-- запрос по остаткам QUIK'ов
--DECLARE @T_dur as Varchar(5) ='T0'
CREATE TABLE #quik_pos (
		[ClientCode] Varchar(12)
		,[AssetCode] Varchar(12)
		,[AssetName] Varchar(128)	
		,[CurrentBal] DECIMAL(19,2)
		,[LimitKind] Varchar(5)
		,[AssetType] int
		,QUIK_LoadDate datetime
)
;WITH tst (
		[ClientCode]
		,[AssetCode]
		,[AssetName]
		,[CurrentBal]
		,[LimitKind]
		,[AssetType]
		,QUIK_LoadDate
) as 
(
SELECT	 [ClientCode] COLLATE Cyrillic_General_CI_AS
		,[CurrCode] COLLATE Cyrillic_General_CI_AS as [AssetCode]
		, '-' as AssetName
		,[CurrentBal]
		,[LimitKind]
		,3 as [AssetType]
		,[LoadDate] as QUIK_LoadDate
FROM	[quikexport].[dbo].[MoneyLimits]
WHERE   LimitKind=@T_dur
UNION
SELECT 	[ClientCode] COLLATE Cyrillic_General_CI_AS
		,[SecCode] COLLATE Cyrillic_General_CI_AS as  [AssetCode]
		,[SecName] as AssetName
		,[CurrentBal]
		,[LimitKind]
		,1 as [AssetType]
		,[LoadDate] as QUIK_LoadDate
FROM	[quikexport].[dbo].[DepoLimits]
WHERE   LimitKind=@T_dur
)
INSERT INTO #quik_pos([ClientCode]
		,[AssetCode]
		,[AssetName]
		,[CurrentBal]
		,[LimitKind]
		,[AssetType]
		,QUIK_LoadDate
		) 
SELECT * FROM tst

SELECT * FROM #quik_pos

SELECT	QRP.*
		,QP.ClientCode
		,QP.[CurrentBal]	
		,QUIK_LoadDate
FROM	#qort_pos as QRP
		LEFT JOIN #quik_pos as QP ON 
			QRP.Subacc_TradeCode  COLLATE Cyrillic_General_CI_AS=QP.[ClientCode] COLLATE Cyrillic_General_CI_AS
			AND QRP.[SecCode]=QP.[AssetCode]