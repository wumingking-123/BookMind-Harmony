import { MyCenterTitle } from '../../../componets/myCenter/MyCenterTitle';
import MyCenterFileSearch from  '../../../componets/myCenter/MyCenterFileSearch';
import FolderFileDataSource from '../../../common/LazyIDataSource/FileListDataSource';
import FolderFileListItem from '../../../componets/myCenter/FolderFileListItem';
import FolderAndFileItem from '../../../componets/dataList/FolderAndFileItem';
import RenameDialog from '../dialog/RenameDialog';
import { hilog } from '@kit.PerformanceAnalysisKit';
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';
import { showMessage } from '../../../componets/common/promptShow';

/**
 * @author 惟草木之零落兮
 * @date 2024/5/22 14:33
 */

// 书架/更多/书籍导入/文件列表

PersistentStorage.persistProp('onSelect', 0);

@Entry
@Component
struct FileManagement {
    @State title: string = '文件管理'

    @State fileList: FolderFileDataSource = new FolderFileDataSource()

    @StorageLink("onSelect") onSelect: number = 0

    dialogController: CustomDialogController | null = new CustomDialogController({
        builder: RenameDialog({
            oldName: "文件管理",
            confirm: this.confirm
        }),
        //autoCancel: true,
        alignment: DialogAlignment.Center,
        offset: { dx: 0, dy: 0 },
        customStyle: true
    })

    confirm(value: string){
        // 新名字
    }

    aboutToAppear(): void {
        this.loadFiles();
    }

    loadFiles() {
        let context = getContext(this) as common.UIAbilityContext;
        let filesDir = context.filesDir;
        this.fileList.clear();

        try {
            let files = fs.listFileSync(filesDir);
            for (let i = 0; i < files.length; i++) {
                let fileName = files[i];
                let filePath = filesDir + '/' + fileName;
                let stat = fs.statSync(filePath);
                
                // 仅显示文件，不显示目录（或者可以根据需要过滤后缀）
                if (!stat.isDirectory()) {
                    let sizeStr = (stat.size / 1024 / 1024).toFixed(2) + " MB";
                    let d = new Date(stat.mtime * 1000);
                    let dateStr = `${d.getFullYear()}/${d.getMonth()+1}/${d.getDate()}`;
                    
                    let ext = fileName.substring(fileName.lastIndexOf('.')).toLowerCase();
                    let icon = $r("app.media.ic_zip");
                    if (ext === '.txt' || ext === '.epub') icon = $r("app.media.my_center_book_icon");
                    if (ext === '.pdf' || ext === '.cbz') icon = $r("app.media.my_center_purify_icon");

                    let newItem: FolderAndFileItem = {
                        title: fileName,
                        icon: icon,
                        size: sizeStr,
                        date: dateStr,
                        isFolder: false,
                        path: filePath
                    };
                    this.fileList.pushData(newItem);
                }
            }
        } catch(e) {
            console.error("Failed to load files: " + e);
        }
    }

    deleteFile(item: FolderAndFileItem, index: number) {
        try {
            if (item.path && fs.accessSync(item.path)) {
                fs.unlinkSync(item.path);
                this.fileList.deleteData(index);
                showMessage("删除成功");
            }
        } catch (e) {
            showMessage("删除失败");
        }
    }

    @Builder
    deleteBuilder(item: FolderAndFileItem, index: number) {
        Row() {
            Button("删除")
                .backgroundColor(Color.Red)
                .fontColor(Color.White)
                .width(80)
                .height("100%")
                .onClick(() => {
                    this.deleteFile(item, index);
                })
        }
    }

    build() {
        Column(){

            // 标题栏
            MyCenterTitle({
                title: this.title,
                isShowEdit: true,
                isShowMore: true,
                onEditClickEvent: ()=>{
                    this.dialogController?.open()
                }
            })

            // 搜索栏
            MyCenterFileSearch({
                onResultCallBack: (value: string)=>{
                    // value 搜索框值发生变化和提交搜索会触发
                    // TODO 执行搜索，此处应做防抖处理
                }
            })

            // 目录层级栏
            Row(){
                Text("TODO 目录层级") //TODO 目录层级
            }
            .margin({top: 12, bottom: 12})

            // 文件+文件夹列表
            Column(){
                List({space: 20}){
                    LazyForEach(this.fileList, (item: FolderAndFileItem, index: number)=>{
                        ListItem(){
                            FolderFileListItem({
                                data: item
                            })
                        }
                        .swipeAction({ end: this.deleteBuilder(item, index) })
                    })
                }
                .width("100%")
                .height("100%")
            }
            .width("100%")
            .layoutWeight(1) // 占满屏幕剩余空间
        }
        .padding({left: 20, right: 20})
    }
}