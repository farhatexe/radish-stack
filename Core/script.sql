USE [master]
GO
/****** Object:  Database [RadishStackDB]    Script Date: 7/17/2017 9:23:47 PM ******/
CREATE DATABASE [RadishStackDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'RadishStackDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\RadishStackDB.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'RadishStackDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\RadishStackDB_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [RadishStackDB] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [RadishStackDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [RadishStackDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [RadishStackDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [RadishStackDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [RadishStackDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [RadishStackDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [RadishStackDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [RadishStackDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [RadishStackDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [RadishStackDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [RadishStackDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [RadishStackDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [RadishStackDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [RadishStackDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [RadishStackDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [RadishStackDB] SET  DISABLE_BROKER 
GO
ALTER DATABASE [RadishStackDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [RadishStackDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [RadishStackDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [RadishStackDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [RadishStackDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [RadishStackDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [RadishStackDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [RadishStackDB] SET RECOVERY FULL 
GO
ALTER DATABASE [RadishStackDB] SET  MULTI_USER 
GO
ALTER DATABASE [RadishStackDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [RadishStackDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [RadishStackDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [RadishStackDB] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [RadishStackDB] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'RadishStackDB', N'ON'
GO
USE [RadishStackDB]
GO
/****** Object:  Table [dbo].[Media]    Script Date: 7/17/2017 9:23:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Media](
	[Id] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](255) NULL,
	[RelativePath] [nvarchar](255) NOT NULL,
	[Status] [int] NOT NULL,
	[CreationDate] [datetime] NOT NULL CONSTRAINT [DF_Media_CreationDate]  DEFAULT (getutcdate()),
	[LastModified] [datetime] NOT NULL CONSTRAINT [DF_Media_LastModified]  DEFAULT (getutcdate()),
	[Type] [int] NOT NULL CONSTRAINT [DF__Media__Type__25869641]  DEFAULT ((0)),
	[PublicId] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_Media] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Post]    Script Date: 7/17/2017 9:23:47 PM ******/
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
	[Photo] [nvarchar](255) NULL,
	[Author] [nvarchar](255) NULL,
	[Gallery] [nvarchar](max) NULL,
	[Widgets] [nvarchar](max) NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_Post] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PostMeta]    Script Date: 7/17/2017 9:23:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PostMeta](
	[Id] [uniqueidentifier] NOT NULL,
	[PostId] [uniqueidentifier] NOT NULL,
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
/****** Object:  Table [dbo].[PostTerm]    Script Date: 7/17/2017 9:23:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PostTerm](
	[Id] [uniqueidentifier] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[PostId] [uniqueidentifier] NOT NULL,
	[TermId] [uniqueidentifier] NOT NULL,
	[Status] [int] NOT NULL,
 CONSTRAINT [PK_PostTerm_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PostType]    Script Date: 7/17/2017 9:23:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PostType](
	[Id] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](400) NOT NULL,
	[ViewPath] [nvarchar](400) NULL,
	[DisplayOrder] [int] NOT NULL,
	[EnableFeatureImage] [bit] NOT NULL,
	[EnableTags] [bit] NOT NULL,
	[EnableDescription] [bit] NOT NULL,
	[EnableSummary] [bit] NOT NULL,
	[EnableDateChoose] [bit] NULL,
	[EnableGallery] [bit] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[EnableCategories] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Icon] [nvarchar](255) NULL,
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
/****** Object:  Table [dbo].[PostWidget]    Script Date: 7/17/2017 9:23:47 PM ******/
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
/****** Object:  Table [dbo].[Setting]    Script Date: 7/17/2017 9:23:47 PM ******/
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
/****** Object:  Table [dbo].[Term]    Script Date: 7/17/2017 9:23:47 PM ******/
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
	[IncludeInTopMenu] [bit] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
	[IsPublic] [bit] NOT NULL,
	[PublicId] [int] IDENTITY(1,1) NOT NULL,
	[PostTypeId] [uniqueidentifier] NOT NULL,
	[ParentId] [uniqueidentifier] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_Term] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[User]    Script Date: 7/17/2017 9:23:47 PM ******/
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
/****** Object:  Table [dbo].[Widget]    Script Date: 7/17/2017 9:23:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Widget](
	[Id] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](255) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[SourceCategories] [nvarchar](255) NULL,
	[SourceTags] [nvarchar](255) NULL,
	[SourcePosts] [nvarchar](255) NULL,
	[IsActive] [bit] NOT NULL,
	[ViewPath] [nvarchar](255) NULL,
	[PostCount] [int] NOT NULL,
	[PublicId] [int] IDENTITY(1,1) NOT NULL,
	[Status] [int] NOT NULL,
	[ReturnTags] [bit] NOT NULL,
	[ReturnCategories] [bit] NOT NULL,
	[ReturnPosts] [bit] NOT NULL,
	[PostType] [nvarchar](255) NOT NULL,
	[Tags] [nvarchar](max) NOT NULL,
	[Categories] [nvarchar](max) NOT NULL,
	[Posts] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_Widget] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET IDENTITY_INSERT [dbo].[Media] ON 

INSERT [dbo].[Media] ([Id], [Title], [RelativePath], [Status], [CreationDate], [LastModified], [Type], [PublicId]) VALUES (N'827c584b-1956-4cd9-b39a-1187fb6c286b', NULL, N'/content/uploaded/a7d15be4-4c1d-4ffe-8233-56c201a77f19.png', 0, CAST(N'2017-07-03 20:31:12.837' AS DateTime), CAST(N'2017-07-03 17:31:12.843' AS DateTime), 0, 5)
INSERT [dbo].[Media] ([Id], [Title], [RelativePath], [Status], [CreationDate], [LastModified], [Type], [PublicId]) VALUES (N'6a917615-7b51-46ea-8f55-1891f7df26d4', NULL, N'/content/uploaded/0ad043d5-aa26-49b8-85b3-1eb4f53e26fc.png', 0, CAST(N'2017-07-03 20:29:58.473' AS DateTime), CAST(N'2017-07-03 17:29:58.480' AS DateTime), 0, 1)
INSERT [dbo].[Media] ([Id], [Title], [RelativePath], [Status], [CreationDate], [LastModified], [Type], [PublicId]) VALUES (N'67ec67f1-4603-4eac-b942-2508ad38704d', NULL, N'/content/uploaded/cf1e1edb-89d8-4041-9078-42b5ab361d07.png', 0, CAST(N'2017-07-04 00:17:09.857' AS DateTime), CAST(N'2017-07-03 21:17:09.870' AS DateTime), 0, 6)
INSERT [dbo].[Media] ([Id], [Title], [RelativePath], [Status], [CreationDate], [LastModified], [Type], [PublicId]) VALUES (N'9697d155-8b20-4322-b9a5-35e9ec203f52', NULL, N'/content/uploaded/c4cc6199-2651-4f55-a475-93ca3922a9ef.png', 0, CAST(N'2017-07-03 20:30:03.887' AS DateTime), CAST(N'2017-07-03 17:30:03.890' AS DateTime), 0, 2)
INSERT [dbo].[Media] ([Id], [Title], [RelativePath], [Status], [CreationDate], [LastModified], [Type], [PublicId]) VALUES (N'5ba990b9-20d2-4102-94bf-c58e50d34b7b', NULL, N'/content/uploaded/1652b416-615c-4413-b064-d74b72e94f2c.png', 0, CAST(N'2017-07-03 20:31:10.897' AS DateTime), CAST(N'2017-07-03 17:31:10.903' AS DateTime), 0, 4)
INSERT [dbo].[Media] ([Id], [Title], [RelativePath], [Status], [CreationDate], [LastModified], [Type], [PublicId]) VALUES (N'8b59fbff-7329-42ff-a8a5-e6386ea037cc', NULL, N'/content/uploaded/b4f3d95f-1ffc-4a8c-9a52-3ebe9fbbca72.png', 0, CAST(N'2017-07-03 20:30:08.677' AS DateTime), CAST(N'2017-07-03 17:30:08.683' AS DateTime), 0, 3)
SET IDENTITY_INSERT [dbo].[Media] OFF
SET IDENTITY_INSERT [dbo].[Post] ON 

INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId], [Photo], [Author], [Gallery], [Widgets], [IsActive]) VALUES (N'81a7af2a-76d2-41ec-a612-02887b82cee0', CAST(N'2017-07-03 20:20:40.753' AS DateTime), N'politics 1', 20, N'<p><strong>fdshfdhg</strong></p>', 0, NULL, NULL, NULL, 11, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, N'/content/uploaded/0ad043d5-aa26-49b8-85b3-1eb4f53e26fc.png', NULL, N'[
  {
    "Path": "/content/uploaded/a7d15be4-4c1d-4ffe-8233-56c201a77f19.png?width=300",
    "Title": null
  },
  {
    "Path": "/content/uploaded/1652b416-615c-4413-b064-d74b72e94f2c.png?width=300",
    "Title": null
  }
]', NULL, NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId], [Photo], [Author], [Gallery], [Widgets], [IsActive]) VALUES (N'017b8c1c-6ac3-419a-b88e-105a5c92a97c', CAST(N'2017-07-03 20:20:08.020' AS DateTime), N'sdfh', -100, N'<p><strong>fdshfdhg</strong></p>', 0, NULL, NULL, NULL, 9, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, NULL, NULL, N'[]', NULL, NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId], [Photo], [Author], [Gallery], [Widgets], [IsActive]) VALUES (N'86bca7c3-7f4a-4dcf-a39d-2d6b7629c934', CAST(N'2017-07-03 20:13:39.407' AS DateTime), N'Home', 20, N'<p>asd</p>', 0, NULL, NULL, NULL, 3, N'0004aef4-1380-40e1-bdbf-5c6dd6e7bddf', NULL, N'/content/uploaded/cf1e1edb-89d8-4041-9078-42b5ab361d07.png', NULL, N'[]', N'{"rows":[{"cols":[{"lg":"12","text":"c2","rows":[{"cols":[{"lg":12,"text":"c2","rows":[],"widgets":[{"widgetid":"ca8b74a6-7602-4da4-9c4e-7ca3612ce768","title":"photo"}]}]}],"widgets":[{"widgetid":"9761548f-92af-4377-bedc-147d9a7aa2f4","title":"slider"}]}]}]}', NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId], [Photo], [Author], [Gallery], [Widgets], [IsActive]) VALUES (N'dcf3a3ba-bc71-4393-bd11-a367dd1ce278', CAST(N'2017-07-03 20:19:46.623' AS DateTime), N'dfgdfg', -100, NULL, 0, NULL, NULL, NULL, 7, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, NULL, NULL, N'[]', NULL, NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId], [Photo], [Author], [Gallery], [Widgets], [IsActive]) VALUES (N'699b4958-75ba-4c18-81a0-a7370d02c4f6', CAST(N'2017-07-03 20:19:02.143' AS DateTime), N'he comes to us', -100, N'<p><strong>asdasd</strong></p>', 0, NULL, NULL, NULL, 5, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, NULL, NULL, N'[]', NULL, NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId], [Photo], [Author], [Gallery], [Widgets], [IsActive]) VALUES (N'8aabee41-9798-4e91-a7d0-bb2cdae90b82', CAST(N'2017-07-03 20:20:13.550' AS DateTime), N'sdfh', -100, N'<p><strong>fdshfdhg</strong></p>', 0, NULL, NULL, NULL, 10, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, NULL, NULL, N'[]', NULL, NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId], [Photo], [Author], [Gallery], [Widgets], [IsActive]) VALUES (N'168171ba-207a-480f-a766-e7c3dd2f7af8', CAST(N'2017-07-03 20:19:13.597' AS DateTime), N'he comes to us', -100, N'<p><strong>asdasd</strong></p>', 0, NULL, NULL, NULL, 6, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, NULL, NULL, N'[]', NULL, NULL)
INSERT [dbo].[Post] ([Id], [CreationDate], [Title], [Status], [Detail], [IsInitial], [ViewPath], [Attachments], [PostMetaValues], [PublicId], [PostTypeId], [ParentId], [Photo], [Author], [Gallery], [Widgets], [IsActive]) VALUES (N'42057c65-52c3-4339-8bf6-ff8a66c91de1', CAST(N'2017-07-03 20:19:54.860' AS DateTime), N'sdfh', -100, N'<p><strong>fdshfdhg</strong></p>', 0, NULL, NULL, NULL, 8, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, NULL, NULL, N'[]', NULL, NULL)
SET IDENTITY_INSERT [dbo].[Post] OFF
INSERT [dbo].[PostTerm] ([Id], [DisplayOrder], [CreationDate], [PostId], [TermId], [Status]) VALUES (N'198e3e77-3f04-4b2b-9547-5f1fe8dc2926', 1, CAST(N'2017-07-03 20:23:50.070' AS DateTime), N'81a7af2a-76d2-41ec-a612-02887b82cee0', N'25e90a30-0f4b-403c-9b5a-4aa5c2699e36', 0)
INSERT [dbo].[PostTerm] ([Id], [DisplayOrder], [CreationDate], [PostId], [TermId], [Status]) VALUES (N'6cdc9ee2-6963-49cc-91e2-803e3e049eb4', 3, CAST(N'2017-07-03 20:24:22.390' AS DateTime), N'81a7af2a-76d2-41ec-a612-02887b82cee0', N'a818b888-6fe9-4881-bd52-699cc51b8f15', 0)
INSERT [dbo].[PostTerm] ([Id], [DisplayOrder], [CreationDate], [PostId], [TermId], [Status]) VALUES (N'd0877c30-29ba-4d69-97a9-806544a4ccdc', 1, CAST(N'2017-07-03 20:23:39.537' AS DateTime), N'81a7af2a-76d2-41ec-a612-02887b82cee0', N'25e90a30-0f4b-403c-9b5a-4aa5c2699e36', -100)
INSERT [dbo].[PostTerm] ([Id], [DisplayOrder], [CreationDate], [PostId], [TermId], [Status]) VALUES (N'22bcfcca-4b78-44b6-b1bf-b33e2c6fd347', 4, CAST(N'2017-07-03 20:23:47.843' AS DateTime), N'81a7af2a-76d2-41ec-a612-02887b82cee0', N'1d9b7506-a35a-4a16-a505-89d00b1d2e6f', 0)
INSERT [dbo].[PostTerm] ([Id], [DisplayOrder], [CreationDate], [PostId], [TermId], [Status]) VALUES (N'c19c3fec-f6bb-4ea8-a86c-e56362f6afd0', 2, CAST(N'2017-07-03 20:23:44.673' AS DateTime), N'81a7af2a-76d2-41ec-a612-02887b82cee0', N'e8821ed0-8002-4252-aba3-722c3b7ef4fd', 0)
SET IDENTITY_INSERT [dbo].[PostType] ON 

INSERT [dbo].[PostType] ([Id], [Title], [ViewPath], [DisplayOrder], [EnableFeatureImage], [EnableTags], [EnableDescription], [EnableSummary], [EnableDateChoose], [EnableGallery], [CreationDate], [EnableCategories], [IsActive], [Icon], [IsSystem], [EnableViewPath], [TermViewPath], [PostMetaFields], [PostMediaList], [EnableWidgets], [Status], [PublicId]) VALUES (N'37ce72cf-6376-47d1-81c7-0322c95587f7', N'News', N'news', 2, 1, 1, 1, 1, NULL, 1, CAST(N'2017-07-03 19:52:09.470' AS DateTime), 1, 1, N'pencil', 0, 0, N'news', NULL, NULL, 0, 0, 3)
INSERT [dbo].[PostType] ([Id], [Title], [ViewPath], [DisplayOrder], [EnableFeatureImage], [EnableTags], [EnableDescription], [EnableSummary], [EnableDateChoose], [EnableGallery], [CreationDate], [EnableCategories], [IsActive], [Icon], [IsSystem], [EnableViewPath], [TermViewPath], [PostMetaFields], [PostMediaList], [EnableWidgets], [Status], [PublicId]) VALUES (N'0004aef4-1380-40e1-bdbf-5c6dd6e7bddf', N'Pages', N'page', 1, 1, 1, 1, 1, 1, 1, CAST(N'2017-10-10 00:00:00.000' AS DateTime), 1, 1, N'tag', 0, 1, N'page', NULL, NULL, 1, 0, 1)
SET IDENTITY_INSERT [dbo].[PostType] OFF
SET IDENTITY_INSERT [dbo].[Term] ON 

INSERT [dbo].[Term] ([Id], [CreationDate], [Title], [TaxonomyId], [Status], [IncludeInTopMenu], [DisplayOrder], [IsPublic], [PublicId], [PostTypeId], [ParentId], [IsActive]) VALUES (N'25e90a30-0f4b-403c-9b5a-4aa5c2699e36', CAST(N'2017-07-03 20:08:24.610' AS DateTime), N'politics', 10, 0, 0, 0, 1, 3, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, 1)
INSERT [dbo].[Term] ([Id], [CreationDate], [Title], [TaxonomyId], [Status], [IncludeInTopMenu], [DisplayOrder], [IsPublic], [PublicId], [PostTypeId], [ParentId], [IsActive]) VALUES (N'a818b888-6fe9-4881-bd52-699cc51b8f15', CAST(N'2017-07-03 20:24:22.350' AS DateTime), N'test', 20, 0, 0, 0, 1, 6, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, 1)
INSERT [dbo].[Term] ([Id], [CreationDate], [Title], [TaxonomyId], [Status], [IncludeInTopMenu], [DisplayOrder], [IsPublic], [PublicId], [PostTypeId], [ParentId], [IsActive]) VALUES (N'e8821ed0-8002-4252-aba3-722c3b7ef4fd', CAST(N'2017-07-03 20:08:35.820' AS DateTime), N'sport', 10, 0, 0, 0, 1, 4, N'37ce72cf-6376-47d1-81c7-0322c95587f7', N'25e90a30-0f4b-403c-9b5a-4aa5c2699e36', 1)
INSERT [dbo].[Term] ([Id], [CreationDate], [Title], [TaxonomyId], [Status], [IncludeInTopMenu], [DisplayOrder], [IsPublic], [PublicId], [PostTypeId], [ParentId], [IsActive]) VALUES (N'1d9b7506-a35a-4a16-a505-89d00b1d2e6f', CAST(N'2017-07-03 20:10:28.847' AS DateTime), N'lebanon', 20, 0, 0, 0, 1, 5, N'37ce72cf-6376-47d1-81c7-0322c95587f7', NULL, 1)
INSERT [dbo].[Term] ([Id], [CreationDate], [Title], [TaxonomyId], [Status], [IncludeInTopMenu], [DisplayOrder], [IsPublic], [PublicId], [PostTypeId], [ParentId], [IsActive]) VALUES (N'cafb98ba-2903-433a-9f1c-ef2b64235b1b', CAST(N'2017-07-03 20:27:30.563' AS DateTime), N'sss', 10, 0, 0, 3, 1, 7, N'37ce72cf-6376-47d1-81c7-0322c95587f7', N'e8821ed0-8002-4252-aba3-722c3b7ef4fd', 1)
SET IDENTITY_INSERT [dbo].[Term] OFF
SET IDENTITY_INSERT [dbo].[User] ON 

INSERT [dbo].[User] ([Id], [PublicId], [CreationDate], [Name], [Username], [Email], [Role], [Status], [PasswordHash], [PasswordSalt], [Photo]) VALUES (N'0004aef4-1380-40e1-bdbf-5c6dd6e7bddf', 1, CAST(N'2017-10-10 00:00:00.000' AS DateTime), N'admin', N'admin', N'admin', 10, 10, N'btWDPPNShuv4Zit7WUnw10K77D8=', N'QRhr7ksom8wrAkQOcycax6PyiI576UkZGUKjOEk+Ewk=', N'')
SET IDENTITY_INSERT [dbo].[User] OFF
SET IDENTITY_INSERT [dbo].[Widget] ON 

INSERT [dbo].[Widget] ([Id], [Title], [CreationDate], [SourceCategories], [SourceTags], [SourcePosts], [IsActive], [ViewPath], [PostCount], [PublicId], [Status], [ReturnTags], [ReturnCategories], [ReturnPosts], [PostType], [Tags], [Categories], [Posts]) VALUES (N'9761548f-92af-4377-bedc-147d9a7aa2f4', N'slider', CAST(N'2017-07-03 23:06:43.907' AS DateTime), NULL, NULL, NULL, 1, N'slider', 10, 4, 0, 1, 1, 1, N'37ce72cf-6376-47d1-81c7-0322c95587f7', N'1d9b7506-a35a-4a16-a505-89d00b1d2e6f', N'e8821ed0-8002-4252-aba3-722c3b7ef4fd', N'81a7af2a-76d2-41ec-a612-02887b82cee0')
INSERT [dbo].[Widget] ([Id], [Title], [CreationDate], [SourceCategories], [SourceTags], [SourcePosts], [IsActive], [ViewPath], [PostCount], [PublicId], [Status], [ReturnTags], [ReturnCategories], [ReturnPosts], [PostType], [Tags], [Categories], [Posts]) VALUES (N'ca8b74a6-7602-4da4-9c4e-7ca3612ce768', N'photo', CAST(N'2017-07-09 00:14:12.120' AS DateTime), NULL, NULL, NULL, 1, N'slider', 10, 5, 0, 1, 1, 1, N'0004aef4-1380-40e1-bdbf-5c6dd6e7bddf', N'1d9b7506-a35a-4a16-a505-89d00b1d2e6f', N'cafb98ba-2903-433a-9f1c-ef2b64235b1b', N'86bca7c3-7f4a-4dcf-a39d-2d6b7629c934')
SET IDENTITY_INSERT [dbo].[Widget] OFF
USE [master]
GO
ALTER DATABASE [RadishStackDB] SET  READ_WRITE 
GO
