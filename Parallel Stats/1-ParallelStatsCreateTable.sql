USE [DBA]
GO

/****** Object:  Table [dbo].[ParallelStatsTasks]    Script Date: 5/11/2016 10:40:37 AM ******/
DROP TABLE [dbo].[ParallelStatsTasks]
GO

/****** Object:  Table [dbo].[ParallelStatsTasks]    Script Date: 5/11/2016 10:40:37 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ParallelStatsTasks](
	[i] [int] IDENTITY(1,1) NOT NULL,
	[Databasename] [varchar](128) NOT NULL,
	[LastUpdate] [smalldatetime] NOT NULL,
	[Processing] [SMALLINT] NOT NULL,
	[Completed] [bit] NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


