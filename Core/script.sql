USE [master]
GO
/****** Object:  Database [Kodek]    Script Date: 10/21/2016 5:37:14 PM ******/
CREATE DATABASE [Kodek]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'GeneralWebsiteDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\GeneralWebsiteDB.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'GeneralWebsiteDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\GeneralWebsiteDB_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [Kodek] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Kodek].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Kodek] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Kodek] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Kodek] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Kodek] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Kodek] SET ARITHABORT OFF 
GO
ALTER DATABASE [Kodek] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Kodek] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [Kodek] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Kodek] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Kodek] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Kodek] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Kodek] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Kodek] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Kodek] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Kodek] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Kodek] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Kodek] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Kodek] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Kodek] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Kodek] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Kodek] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Kodek] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Kodek] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Kodek] SET RECOVERY FULL 
GO
ALTER DATABASE [Kodek] SET  MULTI_USER 
GO
ALTER DATABASE [Kodek] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Kodek] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Kodek] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Kodek] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'Kodek', N'ON'
GO
USE [Kodek]
GO
/****** Object:  StoredProcedure [dbo].[PostLoadAllPaged]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PostLoadAllPaged]
(
	@CategoryIds		nvarchar(MAX) = null,	--a list of category IDs (comma-separated list). e.g. 1,2,3
	@Keywords			nvarchar(4000) = null,
	@SearchDescriptions bit = 0, --a value indicating whether to search by a specified "keyword" in Post descriptions
	@UseFullTextSearch  bit = 0,
	@FullTextMode		int = 0, --0 - using CONTAINS with <prefix_term>, 5 - using CONTAINS and OR with <prefix_term>, 10 - using CONTAINS and AND with <prefix_term>
	@LanguageId			int = 0,
	@OrderBy			int = 0, --0 - position, 5 - Name: A to Z, 6 - Name: Z to A, 10 - Price: Low to High, 11 - Price: High to Low, 15 - creation date
   @PageIndex			int = 0, 
	@PageSize			int = 2147483644,
@TotalRecords		int = null OUTPUT
)
AS
BEGIN
	
	/* Posts that filtered by keywords */
	CREATE TABLE #KeywordPosts
	(
		[PostId] int NOT NULL
	)

	DECLARE
		@SearchKeywords bit,
		@sql nvarchar(max),
		@sql_orderby nvarchar(max)

	SET NOCOUNT ON
	
	--filter by keywords
	SET @Keywords = isnull(@Keywords, '')
	SET @Keywords = rtrim(ltrim(@Keywords))
	IF ISNULL(@Keywords, '') != ''
	BEGIN
		SET @SearchKeywords = 1
		
		IF @UseFullTextSearch = 1
		BEGIN
			--remove wrong chars (' ")
			SET @Keywords = REPLACE(@Keywords, '''', '')
			SET @Keywords = REPLACE(@Keywords, '"', '')
			
			--full-text search
			IF @FullTextMode = 0 
			BEGIN
				--0 - using CONTAINS with <prefix_term>
				SET @Keywords = ' "' + @Keywords + '*" '
			END
			ELSE
			BEGIN
				--5 - using CONTAINS and OR with <prefix_term>
				--10 - using CONTAINS and AND with <prefix_term>

				--clean multiple spaces
				WHILE CHARINDEX('  ', @Keywords) > 0 
					SET @Keywords = REPLACE(@Keywords, '  ', ' ')

				DECLARE @concat_term nvarchar(100)				
				IF @FullTextMode = 5 --5 - using CONTAINS and OR with <prefix_term>
				BEGIN
					SET @concat_term = 'OR'
				END 
				IF @FullTextMode = 10 --10 - using CONTAINS and AND with <prefix_term>
				BEGIN
					SET @concat_term = 'AND'
				END

				--now let's build search string
				declare @fulltext_keywords nvarchar(4000)
				set @fulltext_keywords = N''
				declare @index int		
		
				set @index = CHARINDEX(' ', @Keywords, 0)

				-- if index = 0, then only one field was passed
				IF(@index = 0)
					set @fulltext_keywords = ' "' + @Keywords + '*" '
				ELSE
				BEGIN		
					DECLARE @first BIT
					SET  @first = 1			
					WHILE @index > 0
					BEGIN
						IF (@first = 0)
							SET @fulltext_keywords = @fulltext_keywords + ' ' + @concat_term + ' '
						ELSE
							SET @first = 0

						SET @fulltext_keywords = @fulltext_keywords + '"' + SUBSTRING(@Keywords, 1, @index - 1) + '*"'					
						SET @Keywords = SUBSTRING(@Keywords, @index + 1, LEN(@Keywords) - @index)						
						SET @index = CHARINDEX(' ', @Keywords, 0)
					end
					
					-- add the last field
					IF LEN(@fulltext_keywords) > 0
						SET @fulltext_keywords = @fulltext_keywords + ' ' + @concat_term + ' ' + '"' + SUBSTRING(@Keywords, 1, LEN(@Keywords)) + '*"'	
				END
				SET @Keywords = @fulltext_keywords
			END
		END
		ELSE
		BEGIN
			--usual search by PATINDEX
			SET @Keywords = '%' + @Keywords + '%'
		END
		--PRINT @Keywords

		--Post name
		--SET @sql = '
		--INSERT INTO #KeywordPosts ([PostId])
		--SELECT p.Id
		--FROM Post p with (NOLOCK)
		--WHERE '
		--IF @UseFullTextSearch = 1
		--	SET @sql = @sql + 'CONTAINS(p.[Title], @Keywords) '
		--ELSE
		--	SET @sql = @sql + 'PATINDEX(@Keywords, p.[Title]) > 0 '


		--localized Post name
		SET @sql = 'INSERT INTO #KeywordPosts ([PostId])		
		SELECT lp.EntityId
		FROM LocalizedProperty lp with (NOLOCK)
		WHERE
			lp.LocaleKeyGroup = N''Post''
			AND lp.LanguageId = ' + ISNULL(CAST(@LanguageId AS nvarchar(max)), '0') + '
			AND lp.LocaleKey = N''Title'''
		IF @UseFullTextSearch = 1
			SET @sql = @sql + ' AND CONTAINS(lp.[LocaleValue], @Keywords) '
		ELSE
			SET @sql = @sql + ' AND PATINDEX(@Keywords, lp.[LocaleValue]) > 0 '
	

		IF @SearchDescriptions = 1
		BEGIN
			--Post short description
			--SET @sql = @sql + '
			--UNION
			--SELECT p.Id
			--FROM Post p with (NOLOCK)
			--WHERE '
			--IF @UseFullTextSearch = 1
			--	SET @sql = @sql + 'CONTAINS(p.[ShortDescription], @Keywords) '
			--ELSE
			--	SET @sql = @sql + 'PATINDEX(@Keywords, p.[ShortDescription]) > 0 '


			----Post full description
			--SET @sql = @sql + '
			--UNION
			--SELECT p.Id
			--FROM Post p with (NOLOCK)
			--WHERE '
			--IF @UseFullTextSearch = 1
			--	SET @sql = @sql + 'CONTAINS(p.[Description], @Keywords) '
			--ELSE
			--	SET @sql = @sql + 'PATINDEX(@Keywords, p.[Description]) > 0 '



			--localized Post short description
			SET @sql = @sql + '
			UNION
			SELECT lp.EntityId
			FROM LocalizedProperty lp with (NOLOCK)
			WHERE
				lp.LocaleKeyGroup = N''Post''
				AND lp.LanguageId = ' + ISNULL(CAST(@LanguageId AS nvarchar(max)), '0') + '
				AND lp.LocaleKey = N''ShortDescription'''
			IF @UseFullTextSearch = 1
				SET @sql = @sql + ' AND CONTAINS(lp.[LocaleValue], @Keywords) '
			ELSE
				SET @sql = @sql + ' AND PATINDEX(@Keywords, lp.[LocaleValue]) > 0 '
				

			--localized Post full description
			SET @sql = @sql + '
			UNION
			SELECT lp.EntityId
			FROM LocalizedProperty lp with (NOLOCK)
			WHERE
				lp.LocaleKeyGroup = N''Post''
				AND lp.LanguageId = ' + ISNULL(CAST(@LanguageId AS nvarchar(max)), '0') + '
				AND lp.LocaleKey = N''FullDescription'''
			IF @UseFullTextSearch = 1
				SET @sql = @sql + ' AND CONTAINS(lp.[LocaleValue], @Keywords) '
			ELSE
				SET @sql = @sql + ' AND PATINDEX(@Keywords, lp.[LocaleValue]) > 0 '
		END 	
	
		PRINT (@sql)
		EXEC sp_executesql @sql, N'@Keywords nvarchar(4000)', @Keywords

	END
	ELSE
	
	
	--paging
	DECLARE @PageLowerBound int
	DECLARE @PageUpperBound int
	DECLARE @RowsToReturn int
	SET @RowsToReturn = @PageSize * (@PageIndex + 1)	
	SET @PageLowerBound = @PageSize * @PageIndex
	SET @PageUpperBound = @PageLowerBound + @PageSize + 1
	
	CREATE TABLE #DisplayOrderTmp 
	(
		[Id] int IDENTITY (1, 1) NOT NULL,
		[PostId] int NOT NULL
	)

	SET @sql = '
	INSERT INTO #DisplayOrderTmp ([PostId])
	SELECT p.Id
	FROM
		Post p with (NOLOCK)'	
	
	
		
	
	IF @SearchKeywords = 1
	BEGIN
		SET @sql = @sql + '
		JOIN #KeywordPosts kp
			ON  p.Id = kp.PostId'
	END
  SET @sql = @sql + '
	WHERE
		p.Status = 20'  
	--sorting
	SET @sql_orderby = ''	
	 IF @OrderBy = 15 /* creation date */
		SET @sql_orderby = ' p.[CreationDate] DESC'
	ELSE /* default sorting, 0 (position) */
	BEGIN	
		
		--name
		IF LEN(@sql_orderby) > 0 SET @sql_orderby = @sql_orderby + ', '
		SET @sql_orderby = @sql_orderby + ' p.[Title] ASC'
	END
	
	SET @sql = @sql + '
	ORDER BY' + @sql_orderby
	
	--PRINT (@sql)
	EXEC sp_executesql @sql

	CREATE TABLE #PageIndex 
	(
		[IndexId] int IDENTITY (1, 1) NOT NULL,
		[PostId] int NOT NULL
	)
	INSERT INTO #PageIndex ([PostId])
	SELECT PostId
	FROM #DisplayOrderTmp
	GROUP BY PostId
	ORDER BY min([Id])

	--PRINT @sql
	--total records
	SET @TotalRecords = @@rowcount
	
	DROP TABLE #DisplayOrderTmp
	
	--return Posts
	SELECT TOP (@RowsToReturn)
		p.*
	FROM
		#PageIndex [pi]
		INNER JOIN Post p with (NOLOCK) on p.Id = [pi].[PostId]
	WHERE
		[pi].IndexId > @PageLowerBound AND 
		[pi].IndexId < @PageUpperBound
	ORDER BY
		[pi].IndexId
	
	DROP TABLE #PageIndex
END

GO
/****** Object:  Table [dbo].[ActivityLog]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityLog](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ActivityLogType] [nvarchar](255) NOT NULL,
	[UserId] [int] NOT NULL,
	[Comment] [nvarchar](max) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK__Activity__3214EC075507C0F4] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Form]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Form](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[FirstName] [nvarchar](255) NULL,
	[Email] [nvarchar](1000) NULL,
	[LastName] [nvarchar](255) NULL,
	[Status] [int] NOT NULL,
	[Type] [int] NOT NULL,
	[Phone] [nvarchar](255) NULL,
	[Gender] [nvarchar](255) NULL,
	[Message] [nvarchar](max) NULL,
	[DateChoosen] [nvarchar](255) NULL,
	[media] [nvarchar](max) NULL,
 CONSTRAINT [PK_Form] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Language]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Language](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[LanguageCulture] [nvarchar](20) NOT NULL,
	[UniqueSeoCode] [nvarchar](2) NULL,
	[FlagImageFileName] [nvarchar](50) NULL,
	[Rtl] [bit] NOT NULL,
	[Published] [bit] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
 CONSTRAINT [PK_Language] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LocaleStringResource]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LocaleStringResource](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LanguageId] [int] NOT NULL,
	[ResourceName] [nvarchar](200) NOT NULL,
	[ResourceValue] [nvarchar](max) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
 CONSTRAINT [PK_LocaleStringResource] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LocalizedProperty]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LocalizedProperty](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[EntityId] [int] NOT NULL,
	[LanguageId] [int] NOT NULL,
	[LocaleKeyGroup] [nvarchar](400) NOT NULL,
	[LocaleKey] [nvarchar](400) NOT NULL,
	[LocaleValue] [nvarchar](max) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
 CONSTRAINT [PK_LocalizedProperty] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Log]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Log](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ShortMessage] [nvarchar](max) NOT NULL,
	[FullMessage] [nvarchar](max) NULL,
	[IpAddress] [nvarchar](200) NULL,
	[PageUrl] [nvarchar](max) NULL,
	[ReferrerUrl] [nvarchar](max) NULL,
	[UserId] [int] NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[LogLevelId] [int] NOT NULL,
 CONSTRAINT [PK_Log] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Media]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Media](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RelativePath] [nvarchar](255) NOT NULL,
	[Status] [int] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[Title] [nvarchar](255) NULL,
	[Type] [int] NOT NULL,
 CONSTRAINT [PK_Media] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MenuItem]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MenuItem](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Title] [nvarchar](255) NOT NULL,
	[ParentId] [int] NULL,
	[EntityId] [int] NULL,
	[EntityName] [nvarchar](255) NULL,
	[Url] [nvarchar](500) NULL,
	[DisplayOrder] [int] NOT NULL,
	[IsMega] [bit] NOT NULL,
 CONSTRAINT [PK_MenuItem] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[NewsLetterSubscription]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NewsLetterSubscription](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Email] [nvarchar](255) NOT NULL,
	[Active] [bit] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
 CONSTRAINT [PK__NewsLett__3214EC0753017D2D] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Post]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Post](
	[Id] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[Title] [nvarchar](255) NOT NULL,
	[Status] [int] NOT NULL,
	[Detail] [nvarchar](max) NULL,
	[IsInitial] [bit] NOT NULL,
	[ViewPath] [nvarchar](255) NULL,
	[Attachments] [nvarchar](max) NULL,
	[PostMetaValues] [nvarchar](255) NULL,
	[PublicId] [int] IDENTITY(1,1) NOT NULL,
	[PostTypeId] [uniqueidentifier] NOT NULL,
	[ParentId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Post] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PostMeta]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PostMeta](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PostId] [int] NOT NULL,
	[MetaKey] [nvarchar](255) NOT NULL,
	[MetaValue] [nvarchar](500) NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
 CONSTRAINT [PK_PostMeta] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PostTerm]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PostTerm](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PostId] [int] NOT NULL,
	[TermId] [int] NOT NULL,
	[Order] [int] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
 CONSTRAINT [PK_PostTerm] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PostType]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PostType](
	[Id] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](400) NOT NULL,
	[ViewPath] [nvarchar](400) NOT NULL,
	[DisplayOrder] [int] NOT NULL,
	[EnableFeatureImage] [bit] NOT NULL,
	[EnableTags] [bit] NOT NULL,
	[EnableDescription] [bit] NOT NULL,
	[EnableSummary] [bit] NOT NULL,
	[EnableLocation] [bit] NOT NULL,
	[EnableDateChoose] [bit] NOT NULL,
	[EnableGallery] [bit] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[EnableCategories] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Icon] [nvarchar](255) NOT NULL,
	[IsSystem] [bit] NOT NULL,
	[EnableViewPath] [bit] NOT NULL,
	[TermViewPath] [nvarchar](255) NULL,
	[PostMetaFields] [nvarchar](max) NULL,
	[PostMediaList] [nvarchar](255) NULL,
	[EnableWidgets] [bit] NOT NULL,
	[Status] [int] NOT NULL,
	[PublicId] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_PostType_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PostWidget]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PostWidget](
	[Id] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[WidgetId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
	[Location] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[PublicId] [int] IDENTITY(1,1) NOT NULL,
	[PostId] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_PostWidget_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Setting]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Setting](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[Value] [nvarchar](2000) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Term]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Term](
	[Id] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[Title] [nvarchar](255) NOT NULL,
	[TaxonomyId] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[Count] [int] NOT NULL,
	[IncludeInTopMenu] [bit] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
	[IsPublic] [bit] NOT NULL,
	[PublicId] [int] IDENTITY(1,1) NOT NULL,
	[PostTypeId] [uniqueidentifier] NOT NULL,
	[ParentId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Term] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UrlRecord]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UrlRecord](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[EntityId] [int] NOT NULL,
	[EntityName] [nvarchar](400) NOT NULL,
	[Slug] [nvarchar](400) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LanguageId] [int] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[User]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[User](
	[Id] [uniqueidentifier] NOT NULL,
	[PublicId] [int] IDENTITY(1,1) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Username] [nvarchar](255) NOT NULL,
	[Email] [nvarchar](255) NOT NULL,
	[Role] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[PasswordHash] [varchar](256) NOT NULL,
	[PasswordSalt] [varchar](256) NOT NULL,
	[Photo] [varchar](256) NULL,
 CONSTRAINT [PK_User] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Widget]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Widget](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](255) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModified] [datetime] NOT NULL,
	[SourceCategorys] [nvarchar](255) NULL,
	[SourceTags] [nvarchar](255) NULL,
	[SourcePosts] [nvarchar](255) NULL,
	[IsActive] [bit] NOT NULL,
	[ViewPath] [nvarchar](255) NULL,
	[Config] [nvarchar](500) NULL,
	[PostCount] [int] NOT NULL,
 CONSTRAINT [PK_Widget] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[vPosts]    Script Date: 10/21/2016 5:37:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vPosts]
AS
SELECT        Id, Title, Status, CreationDate, PostTypeId, LastModified, ISNULL((STUFF
                             ((SELECT        CAST(N' | ' + t .Title AS nVARCHAR(500))
                                 FROM            postterm pt INNER JOIN
                                                          term t ON t .id = pt.termid
                                 WHERE        (pt.PostId = p.Id)
                                 ORDER BY t .IsPublic FOR XML PATH('')), 1, 2, '')), '') AS Terms, ISNULL((STUFF
                             ((SELECT        CAST(',' + CAST(t .Id AS VARCHAR(10)) AS VARCHAR(MAX))
                                 FROM            postterm pt INNER JOIN
                                                          term t ON t .id = pt.termid
                                 WHERE        (pt.PostId = p.Id) FOR XML PATH('')), 1, 1, '')), '') AS TermIds
FROM            dbo.Post p


GO
SET IDENTITY_INSERT [dbo].[Media] ON 

INSERT [dbo].[Media] ([Id], [RelativePath], [Status], [CreationDate], [LastModified], [Title], [Type]) VALUES (1, N'/content/uploaded/4aa46d62-b08b-4ecb-bd40-47f9a300f46d.jpg', 0, CAST(0x0000A643010FA95D AS DateTime), CAST(0x0000A643010FA95D AS DateTime), NULL, 0)
INSERT [dbo].[Media] ([Id], [RelativePath], [Status], [CreationDate], [LastModified], [Title], [Type]) VALUES (2, N'/content/uploaded/47b78006-fd31-4681-b458-3fe8051851ab.jpg', 0, CAST(0x0000A643010FBC6E AS DateTime), CAST(0x0000A643010FBC6E AS DateTime), NULL, 0)
INSERT [dbo].[Media] ([Id], [RelativePath], [Status], [CreationDate], [LastModified], [Title], [Type]) VALUES (3, N'/content/uploaded/bd38fef3-4c0f-4979-a0b5-5b7680832162.jpg', 0, CAST(0x0000A643010FC209 AS DateTime), CAST(0x0000A643010FC209 AS DateTime), NULL, 0)
INSERT [dbo].[Media] ([Id], [RelativePath], [Status], [CreationDate], [LastModified], [Title], [Type]) VALUES (4, N'/content/uploaded/1a2cde39-70f5-4aac-a5ea-998976d3d6d2.jpg', 0, CAST(0x0000A64301132A34 AS DateTime), CAST(0x0000A64301132A34 AS DateTime), NULL, 0)
INSERT [dbo].[Media] ([Id], [RelativePath], [Status], [CreationDate], [LastModified], [Title], [Type]) VALUES (5, N'/content/uploaded/ed42a634-e979-48e7-b5d5-de98baf77089.jpg', 0, CAST(0x0000A64301132EE7 AS DateTime), CAST(0x0000A64301132EE7 AS DateTime), NULL, 0)
SET IDENTITY_INSERT [dbo].[Media] OFF
SET IDENTITY_INSERT [dbo].[MenuItem] ON 

INSERT [dbo].[MenuItem] ([Id], [CreationDate], [LastModified], [IsActive], [Title], [ParentId], [EntityId], [EntityName], [Url], [DisplayOrder], [IsMega]) VALUES (1, CAST(0x0000A64301171495 AS DateTime), CAST(0x0000A64301171496 AS DateTime), 1, N'hyuiyui', NULL, 0, N'None', N'yui', 0, 0)
SET IDENTITY_INSERT [dbo].[MenuItem] OFF
SET IDENTITY_INSERT [dbo].[Post] ON 

INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId]) VALUES (N'37ab8dac-c430-4a13-9ded-036c9e1feda9', CAST(0x0000A65801291CFE AS DateTime), N'gdfgdf', 10, N'<p>gdfgdfgdfg</p>', 0, NULL, N'[{"Key":"Standard","Id":0,"Value":null,"Gallery":"","PostAttachments":null},{"Key":"Gallery","Id":0,"Value":null,"Gallery":"","PostAttachments":null}]', NULL, 6, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9811', NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId]) VALUES (N'b3cc374f-2f3f-4d14-99b3-090f2b5ef7ff', CAST(0x0000A658012921C3 AS DateTime), N'gdfgdf', 10, N'<p>gdfgdfgdfg</p>', 0, NULL, N'[{"Key":"Standard","Id":0,"Value":null,"Gallery":"","PostAttachments":null},{"Key":"Gallery","Id":0,"Value":null,"Gallery":"","PostAttachments":null}]', NULL, 7, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9811', NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId]) VALUES (N'd23bc91b-5791-454e-8fed-269d00826ce0', CAST(0x0000A658012938B8 AS DateTime), N'Home', 20, N'<p>Home</p>', 0, NULL, N'[{"Key":"Standard","Id":0,"Value":null,"Gallery":"","PostAttachments":null},{"Key":"Gallery","Id":0,"Value":"Gallery","Gallery":"[]","PostAttachments":null}]', NULL, 9, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9811', NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId]) VALUES (N'60a5bd72-eaf5-4f02-85bf-4f191f6b9815', CAST(0x0000A64300000000 AS DateTime), N'News 1', 20, N'<p><strong>hjghjghjhgj</strong></p>
<p>tyutyutyu<strong>&nbsp;</strong></p>', 0, NULL, N'[{"Key":"Big","Id":5,"Value":"/content/uploaded/ed42a634-e979-48e7-b5d5-de98baf77089.jpg","Gallery":"","PostAttachments":null},{"Key":"Standard","Id":4,"Value":"/content/uploaded/1a2cde39-70f5-4aac-a5ea-998976d3d6d2.jpg","Gallery":"","PostAttachments":null},{"Key":"Thumb","Id":0,"Value":null,"Gallery":"","PostAttachments":null}]', NULL, 2, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9819', NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId]) VALUES (N'60a5bd72-eaf5-4f02-85bf-4f191f6b9819', CAST(0x0000A64300000000 AS DateTime), N'Home1', 20, N'<p><strong>yujtyutyut<img src="/content/uploaded/CnbySrOXEAAEDYj.jpg" /></strong></p>', 0, NULL, N'[{"Key":"Big","Id":0,"Value":null,"Gallery":"","PostAttachments":null},{"Key":"Standard","Id":0,"Value":null,"Gallery":"","PostAttachments":null},{"Key":"Thumb","Id":0,"Value":null,"Gallery":"","PostAttachments":null}]', NULL, 1, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9819', NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId]) VALUES (N'e52ae4fe-0eed-4c74-b5b6-f618eea0da19', CAST(0x0000A65801292C9B AS DateTime), N'gdfgdf', 10, N'<p>gdfgdfgdfg</p>', 0, NULL, N'[{"Key":"Standard","Id":0,"Value":null,"Gallery":"","PostAttachments":null},{"Key":"Gallery","Id":0,"Value":null,"Gallery":"","PostAttachments":null}]', NULL, 8, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9811', NULL)
SET IDENTITY_INSERT [dbo].[Post] OFF
SET IDENTITY_INSERT [dbo].[PostTerm] ON 

INSERT [dbo].[PostTerm] ([Id], [PostId], [TermId], [Order], [LastModified], [CreationDate]) VALUES (1, 2, 1, 0, CAST(0x0000A643011321B7 AS DateTime), CAST(0x0000A643011321B7 AS DateTime))
SET IDENTITY_INSERT [dbo].[PostTerm] OFF
SET IDENTITY_INSERT [dbo].[PostType] ON 

INSERT [dbo].[PostType] ([Id], [Name], [ViewPath], [DisplayOrder], [EnableFeatureImage], [EnableTags], [EnableDescription], [EnableSummary], [EnableLocation], [EnableDateChoose], [EnableGallery], [CreationDate], [LastModified], [EnableCategories], [IsActive], [Icon], [IsSystem], [EnableViewPath], [TermViewPath], [PostMetaFields], [PostMediaList], [EnableWidgets], [Status], [PublicId]) VALUES (N'60a5bd72-eaf5-4f02-85bf-4f191f6b9811', N'الصفحات', N'PostDetail.Simple', 1, 1, 0, 0, 1, 0, 0, 1, CAST(0x0000A52D00000000 AS DateTime), CAST(0x0000A53F00CA435F AS DateTime), 0, 1, N'link', 0, 1, NULL, NULL, N'[{Key:"Standard",Value:""},{Key:"Gallery",Value:""}]', 1, 0, 1)
INSERT [dbo].[PostType] ([Id], [Name], [ViewPath], [DisplayOrder], [EnableFeatureImage], [EnableTags], [EnableDescription], [EnableSummary], [EnableLocation], [EnableDateChoose], [EnableGallery], [CreationDate], [LastModified], [EnableCategories], [IsActive], [Icon], [IsSystem], [EnableViewPath], [TermViewPath], [PostMetaFields], [PostMediaList], [EnableWidgets], [Status], [PublicId]) VALUES (N'60a5bd72-eaf5-4f02-85bf-4f191f6b9812', N'Post', N'PostDetail.Simple', 2, 1, 1, 1, 1, 1, 1, 1, CAST(0x0000A52D00000000 AS DateTime), CAST(0x0000A52D00000000 AS DateTime), 1, 0, N'pencil', 1, 0, NULL, NULL, NULL, 0, 0, 2)
INSERT [dbo].[PostType] ([Id], [Name], [ViewPath], [DisplayOrder], [EnableFeatureImage], [EnableTags], [EnableDescription], [EnableSummary], [EnableLocation], [EnableDateChoose], [EnableGallery], [CreationDate], [LastModified], [EnableCategories], [IsActive], [Icon], [IsSystem], [EnableViewPath], [TermViewPath], [PostMetaFields], [PostMediaList], [EnableWidgets], [Status], [PublicId]) VALUES (N'60a5bd72-eaf5-4f02-85bf-4f191f6b9814', N'Navigation Menu', N'PostDetail.Simple', 3, 1, 1, 1, 1, 1, 1, 1, CAST(0x0000A52D00000000 AS DateTime), CAST(0x0000A52D00000000 AS DateTime), 1, 0, N'heart', 1, 0, NULL, NULL, NULL, 0, 0, 3)
INSERT [dbo].[PostType] ([Id], [Name], [ViewPath], [DisplayOrder], [EnableFeatureImage], [EnableTags], [EnableDescription], [EnableSummary], [EnableLocation], [EnableDateChoose], [EnableGallery], [CreationDate], [LastModified], [EnableCategories], [IsActive], [Icon], [IsSystem], [EnableViewPath], [TermViewPath], [PostMetaFields], [PostMediaList], [EnableWidgets], [Status], [PublicId]) VALUES (N'60a5bd72-eaf5-4f02-85bf-4f191f6b9816', N'Revision', N'PostDetail.Simple', 4, 1, 1, 1, 1, 1, 1, 1, CAST(0x0000A52D00000000 AS DateTime), CAST(0x0000A52D00000000 AS DateTime), 1, 0, N'heart', 1, 0, NULL, NULL, NULL, 0, 0, 4)
INSERT [dbo].[PostType] ([Id], [Name], [ViewPath], [DisplayOrder], [EnableFeatureImage], [EnableTags], [EnableDescription], [EnableSummary], [EnableLocation], [EnableDateChoose], [EnableGallery], [CreationDate], [LastModified], [EnableCategories], [IsActive], [Icon], [IsSystem], [EnableViewPath], [TermViewPath], [PostMetaFields], [PostMediaList], [EnableWidgets], [Status], [PublicId]) VALUES (N'60a5bd72-eaf5-4f02-85bf-4f191f6b9817', N'Attachment', N'PostDetail.Simple', 5, 1, 1, 1, 1, 1, 1, 1, CAST(0x0000A52D00000000 AS DateTime), CAST(0x0000A52D00000000 AS DateTime), 1, 0, N'heart', 1, 0, NULL, NULL, NULL, 0, 0, 5)
INSERT [dbo].[PostType] ([Id], [Name], [ViewPath], [DisplayOrder], [EnableFeatureImage], [EnableTags], [EnableDescription], [EnableSummary], [EnableLocation], [EnableDateChoose], [EnableGallery], [CreationDate], [LastModified], [EnableCategories], [IsActive], [Icon], [IsSystem], [EnableViewPath], [TermViewPath], [PostMetaFields], [PostMediaList], [EnableWidgets], [Status], [PublicId]) VALUES (N'60a5bd72-eaf5-4f02-85bf-4f191f6b9819', N'الأخبار', N'PostDetail.Sidebar', 8, 1, 1, 1, 1, 1, 1, 1, CAST(0x0000A52D00000000 AS DateTime), CAST(0x0000A53900D8C29B AS DateTime), 1, 1, N'pencil', 0, 0, NULL, NULL, N'[{Key:"Big",Value:""},{Key:"Standard",Value:""},{Key:"Thumb",Value:""}]', 0, 0, 6)
SET IDENTITY_INSERT [dbo].[PostType] OFF
SET IDENTITY_INSERT [dbo].[Term] ON 

INSERT [dbo].[Term] ([Id], [CreationDate], [Title], [TaxonomyId], [Status], [Count], [IncludeInTopMenu], [DisplayOrder], [IsPublic], [PublicId], [PostTypeId], [ParentId]) VALUES (N'4bba9be0-96f8-4d9f-a98a-0aff06e48110', CAST(0x0000A658011DA435 AS DateTime), N'رياضة', 10, 0, 0, 0, 2, 1, 1, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9819', N'00000000-0000-0000-0000-000000000000')
INSERT [dbo].[Term] ([Id], [CreationDate], [Title], [TaxonomyId], [Status], [Count], [IncludeInTopMenu], [DisplayOrder], [IsPublic], [PublicId], [PostTypeId], [ParentId]) VALUES (N'4df3f4c6-b431-444a-b663-10f8c4a1710d', CAST(0x0000A65801229E10 AS DateTime), N'لبنان', 0, 0, 0, 0, 0, 1, 2, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9819', N'00000000-0000-0000-0000-000000000000')
INSERT [dbo].[Term] ([Id], [CreationDate], [Title], [TaxonomyId], [Status], [Count], [IncludeInTopMenu], [DisplayOrder], [IsPublic], [PublicId], [PostTypeId], [ParentId]) VALUES (N'b1306054-f041-4206-a624-8a307aa1dd9f', CAST(0x0000A65801258755 AS DateTime), N'tag1', 20, 0, 0, 0, 3, 1, 4, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9819', NULL)
INSERT [dbo].[Term] ([Id], [CreationDate], [Title], [TaxonomyId], [Status], [Count], [IncludeInTopMenu], [DisplayOrder], [IsPublic], [PublicId], [PostTypeId], [ParentId]) VALUES (N'5909d1bb-11a0-4864-93c4-d3a9b05179d1', CAST(0x0000A6580124EDE9 AS DateTime), N'rtyrty', 0, 0, 0, 0, 0, 1, 3, N'60a5bd72-eaf5-4f02-85bf-4f191f6b9819', N'00000000-0000-0000-0000-000000000000')
SET IDENTITY_INSERT [dbo].[Term] OFF
SET IDENTITY_INSERT [dbo].[User] ON 

INSERT [dbo].[User] ([Id], [PublicId], [CreationDate], [Name], [Username], [Email], [Role], [Status], [PasswordHash], [PasswordSalt], [Photo]) VALUES (N'31bfd028-3d59-4445-be27-bf63d4b238f5', 2, CAST(0x0000A69B00000000 AS DateTime), N'admin', N'admin', N'admin', 10, 30, N'1qU0fcP3RHp4Gur/us6rS5GKc3T2EWh7RRbmU4BDEgI=', N'1qU0fcP3RHp4Gur/us6rS5GKc3T2EWh7RRbmU4BDEgI=', NULL)
SET IDENTITY_INSERT [dbo].[User] OFF
SET IDENTITY_INSERT [dbo].[Widget] ON 

INSERT [dbo].[Widget] ([Id], [Title], [CreationDate], [LastModified], [SourceCategorys], [SourceTags], [SourcePosts], [IsActive], [ViewPath], [Config], [PostCount]) VALUES (1, N'slider', CAST(0x0000A643011506B5 AS DateTime), CAST(0x0000A643012CE5B4 AS DateTime), NULL, NULL, NULL, 1, N'Widget.Slider', N'{"PostType":"8","Tags":"","ReturnTags":false,"Categorys":"","ReturnCategorys":false,"Posts":"2","ReturnPosts":true}', 10)
SET IDENTITY_INSERT [dbo].[Widget] OFF
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_LocaleStringResource]    Script Date: 10/21/2016 5:37:14 PM ******/
CREATE NONCLUSTERED INDEX [IX_LocaleStringResource] ON [dbo].[LocaleStringResource]
(
	[ResourceName] ASC,
	[LanguageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20151029-144730]    Script Date: 10/21/2016 5:37:14 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20151029-144730] ON [dbo].[Post]
(
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ActivityLog] ADD  CONSTRAINT [DF_ActivityLog_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[ActivityLog] ADD  CONSTRAINT [DF_ActivityLog_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[Form] ADD  CONSTRAINT [DF_Form_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Form] ADD  CONSTRAINT [DF_Form_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[Form] ADD  CONSTRAINT [DF_Form_DateChoosen]  DEFAULT (getdate()) FOR [DateChoosen]
GO
ALTER TABLE [dbo].[Language] ADD  CONSTRAINT [DF_Language_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Language] ADD  CONSTRAINT [DF_Language_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[LocaleStringResource] ADD  CONSTRAINT [DF_LocaleStringResource_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[LocaleStringResource] ADD  CONSTRAINT [DF_LocaleStringResource_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[LocalizedProperty] ADD  CONSTRAINT [DF_LocalizedProperty_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[LocalizedProperty] ADD  CONSTRAINT [DF_LocalizedProperty_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[Log] ADD  CONSTRAINT [DF_Log_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Log] ADD  CONSTRAINT [DF_Log_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[Media] ADD  CONSTRAINT [DF_Media_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Media] ADD  CONSTRAINT [DF_Media_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[Media] ADD  DEFAULT ((0)) FOR [Type]
GO
ALTER TABLE [dbo].[MenuItem] ADD  CONSTRAINT [DF_MenuItem_DisplayOrder]  DEFAULT ((0)) FOR [DisplayOrder]
GO
ALTER TABLE [dbo].[MenuItem] ADD  CONSTRAINT [DF_MenuItem_IsMega]  DEFAULT ((0)) FOR [IsMega]
GO
ALTER TABLE [dbo].[Post] ADD  CONSTRAINT [DF_Post_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Post] ADD  CONSTRAINT [DF_Post_IsInitial]  DEFAULT ((0)) FOR [IsInitial]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_EnableFeatureImage]  DEFAULT ((0)) FOR [EnableFeatureImage]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_EnableTags]  DEFAULT ((0)) FOR [EnableTags]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_EnableDescription]  DEFAULT ((0)) FOR [EnableDescription]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_EnableSummary]  DEFAULT ((0)) FOR [EnableSummary]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_EnableLocation]  DEFAULT ((0)) FOR [EnableLocation]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_EnableDateChoose]  DEFAULT ((0)) FOR [EnableDateChoose]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_EnableGallery]  DEFAULT ((0)) FOR [EnableGallery]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_IsActive]  DEFAULT ((0)) FOR [IsActive]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_IsSystem]  DEFAULT ((0)) FOR [IsSystem]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_EnableViewPath]  DEFAULT ((1)) FOR [EnableViewPath]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_EnableWidgets]  DEFAULT ((0)) FOR [EnableWidgets]
GO
ALTER TABLE [dbo].[PostType] ADD  CONSTRAINT [DF_PostType_Status]  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[PostWidget] ADD  CONSTRAINT [DF_PostWidget_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[PostWidget] ADD  CONSTRAINT [DF_PostWidget_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[PostWidget] ADD  CONSTRAINT [DF_PostWidget_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[PostWidget] ADD  CONSTRAINT [DF_PostWidget_Status]  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[Setting] ADD  CONSTRAINT [DF_Setting_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Setting] ADD  CONSTRAINT [DF_Setting_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[Term] ADD  CONSTRAINT [DF_Term_Count]  DEFAULT ((0)) FOR [Count]
GO
ALTER TABLE [dbo].[Term] ADD  CONSTRAINT [DF_Term_IncludeInTopMenu]  DEFAULT ((0)) FOR [IncludeInTopMenu]
GO
ALTER TABLE [dbo].[Term] ADD  CONSTRAINT [DF_Term_DisplayOrder]  DEFAULT ((0)) FOR [DisplayOrder]
GO
ALTER TABLE [dbo].[Term] ADD  CONSTRAINT [DF_Term_IsPublic]  DEFAULT ((1)) FOR [IsPublic]
GO
ALTER TABLE [dbo].[UrlRecord] ADD  CONSTRAINT [DF_UrlRecord_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[UrlRecord] ADD  CONSTRAINT [DF_UrlRecord_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_User_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Widget] ADD  CONSTRAINT [DF_Widget_CreationDate]  DEFAULT (getutcdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Widget] ADD  CONSTRAINT [DF_Widget_LastModified]  DEFAULT (getutcdate()) FOR [LastModified]
GO
ALTER TABLE [dbo].[Widget] ADD  DEFAULT ((12)) FOR [PostCount]
GO
ALTER TABLE [dbo].[LocaleStringResource]  WITH CHECK ADD  CONSTRAINT [FK_LocaleStringResource_Language] FOREIGN KEY([LanguageId])
REFERENCES [dbo].[Language] ([Id])
GO
ALTER TABLE [dbo].[LocaleStringResource] CHECK CONSTRAINT [FK_LocaleStringResource_Language]
GO
ALTER TABLE [dbo].[PostWidget]  WITH CHECK ADD  CONSTRAINT [FK_PostWidget_Widget] FOREIGN KEY([WidgetId])
REFERENCES [dbo].[Widget] ([Id])
GO
ALTER TABLE [dbo].[PostWidget] CHECK CONSTRAINT [FK_PostWidget_Widget]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[21] 4[24] 2[22] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 2730
         Width = 5100
         Width = 1500
         Width = 1500
         Width = 3450
         Width = 1500
         Width = 3615
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vPosts'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vPosts'
GO
USE [master]
GO
ALTER DATABASE [Kodek] SET  READ_WRITE 
GO
