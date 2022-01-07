# Shell-Script
Linux上使用的Bash Shell脚本集合
X_script 
为什么编写脚本
自从(被)将环境迁移到Linux后，深深感受到在Linux下操作实在是太麻烦。大量的重复操作实在是浪费生命，比方说复杂的编译选项设置、还有万恶的 git <operation> 真是让人痛不欲生。所以写了一些小脚本，提升一下Linux下操作的用户体验。哦，为什么要带个X呢？主要是听着帅 (′д｀ )…彡
脚本编写原则
- 尽量减少所有人“不必要”参与的操作
- 除非必要，减少接口数量
- 良好的人机交互
脚本列表
http://git.intra.123u.com/huashengge/X_script

build_X 一键编译脚本：
在项目编译过程中我们总是需要设置一些编译选项，如Asan=On这一类的，还有就是vim使用者需要生成compile.json需要增加编译选项，这些操作不但麻烦而且git仓库会形成更改。除此之外，我们的编译也是非常多的操作，如需要先编译战斗库后编proto，然后才可以编译server。build_X.sh将上述的操作集合了一下，能够一键编译lib/server并生成软连接与.json文件。(由于build_X.sh依赖于目前库内的几个脚本如create_cmake.sh等，所以create_cmake.sh在被改动后可能build_X.sh对于脚本的处理会过时，如果在执行一键编译后库内有额外的改动，请即时联系我QAQ@葛华盛 )
使用方法
将build_X.sh放到与roserver/rogamelibs同级目录，运行脚本:
$ ./build_X.sh  // 一键编译，默认64核
$ ./build_X.sh <cpu_num>  //指定核数编译


git_X 常用git操作脚本
除开令人头疼的编译步骤外，最麻烦就是就是一些 git 的操作。很多时候，在代码没有改动的情况下，我们做的多数操作都是非常简单的。如所有分支拉新、集体切到某个本地/远端的分支、fetch所有分支等等，但由于我们的仓库是分离的，来回的cd与git命令是非常麻烦的。git_X.sh 集合了四个常用的简单git操作，尽量使简单git操作一条命令就搞定。
使用方法
git_X.sh支持七种操作符，操作符间能够使用 '/' 连接，同时运行。且操作符之间有优先级关系(优先级高的操作符将优先运行)操作符及其优先级如下：
- clean: 优先级最高的操作符，将本地工作区(未暂存)的修改与新增文件丢弃
- fetch: 拉新所有分支到仓库
- checkout: 切换分支，需要输入一个参数(分支名)，如果本地分支已经切出就checkout到已切出的本地分支，如果本地分支还未切出则将checkout到origin/<branch_name>
- pull: 拉取所有仓库并merge到本地分支
- gc: 相当于git help gc
- newbranch: 切出一个新的本地分支(checkout -b)，如果已存在本地或是origin分支，将会提示失败
- syncorigin: 主要是配合newbranch使用，在切出分支后，将新的分支推到远端，同时将本地分支与远程分支建立关联
将git_X.sh放到与roserver/rogamelibs/config同级目录，运行脚本:（使用脚本的操作符时，不需要关注其顺序，最后的操作执行顺序由操作符间优先级决定）
$ ./git_X.sh fetch  //拉取所有分支
$ ./git_X.sh clean/fetch  //清空所有本地修改并拉取所有分支
$ ./git_X.sh checkout <local_branch_name> // 如果输入的branch_name是已经切出的，会切到本地
$ ./git_X.sh checkout <origin_branch_name>  // 如果输入的branch_name是还没有切出的，会切到origin
$ ./git_X.sh pull //pull所有当前分支
// ---- 一些复杂操作 ----
// 1).切到某个本地/origin分支并拉新
$ ./git_X.sh checkout/pull <branch_name>
// 2).切到某个刚推送到远端的分支(不在origin)并拉新
$ ./git_X.sh fetch/checkout <branch_name>
// 3).放弃本地修改并拉新
$ ./git_X.sh clean/pull
// 4).放弃本地修改，切到某个本地/远程分支
$ ./git_X.sh clean/fetch/checkout/pull <branch_name>
// 5).切出一个新的分支并推送到远端
$ ./git_X.sh newbranch/syncorigin <branch_name>
// 6).git gc
$ ./git_X.sh gc

定义你自己的快捷命令
您可以自定义您的快捷命令，可以选取已有操作符中的几种，形成一个新的快捷指令。这样能够减少脚本参数的输入。
以下是目前已有的几种快捷指令：
DEFINE_CMDS=("reset" "setto" "neworigin")
reset=clean/pull
setto=fetch/checkout/pull
neworigin=newbranch/syncorigin

慎用clean
clean是一个非常危险的命令，会将你工作区且未暂存的文件全部丢弃，尤其是由于其是没有stage的，丢弃后意味着你再也找不回来了。所以，除非你有足够的确信，否则不要轻易使用clean。
仓库间同步问题
在编写脚本时最让我头疼的就是仓库间内容同步的问题。举个例子来说，对于checkout操作来说，如果在rosever仓库存在某个本地分支而libs仓库不存在此本地分支的情况下。如果简单使用./git_X.sh checkout <branch_name> 就会导致两个仓库的分支不同步。
对此情况，由于对于脚本的层面很难判断仓库的状态，实际上我将这种责任“推卸”给了脚本的使用者。如上面这情况下，如果你希望确保仓库间的同步，请使用 ./git_X.sh checkout/pull <branch_name> 命令。
实际上，即使情况变得更严峻，如 config 仓库分支没有fetch、lib仓库没有checkout本地分支、server仓库已checkout出本地分支这种情况。我们也可以使用 ./git_X.sh fetch/checkout/pull <branch_name> 来解决这个问题。


