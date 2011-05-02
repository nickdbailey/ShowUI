## Select-GraphicalFilteredObject.ps1
## Use a graphical interface to select (and pass-through) pipeline objects
## by Lee Holmes (http://www.leeholmes.com/blog)
Import-Module ShowUI

## Get the item as it would be displayed by Format-Table
## Generate the window
Show-UI -Title "Object Filter" -MinWidth 400 -MaxWidth 1000 -Height 600 {
   param($InputItems)
   Grid -Margin 5 -RowDefinitions Auto, *, Auto, Auto {

      # New-ScriptDataSource {  } -Input $InputItems -RunFirst
      $GLOBAL:originalItems = @{}
      $GLOBAL:orderedItems = New-Object System.Collections.ArrayList

      ## Convert input to string representations
      foreach($item in $InputItems) {
         $stringRepresentation = (($item | ft -HideTableHeaders | Out-String )-Split"\n")[-4].trimEnd()
         $GLOBAL:originalItems[$stringRepresentation] = $item
         $null = $orderedItems.Add($stringRepresentation)
      }

## Filter selected items to what's been typed
function SearchText_KeyUp
{
    if($this.Text)
    {
        $items.Clear()
        try
        {
            ## If this is a regex, do a regex match
            $orderedItems | ? { $_ -match $this.Text } | % { $items.Add($_) }
        }
        catch
        {
            ## If the regex threw, do simple text match
            $items.Clear()
            $orderedItems | 
                ? { $_ -like ("*" + [System.Management.Automation.WildcardPattern]::Escape($this.Text) + "*") } |
                    % { $items.Add($_) }
        }
    }
}


## Send the selected items down the pipeline
function OK_Click
{
    $selectedItems = Select-UIElement "Object Filter" SelectedItems
    $source = $selectedItems.Items
    
    if($selectedItems.SelectedIndex -ge 0)
    {
        $source = $selectedItems.SelectedItems
    }

    $GLOBAL:originalItems[$source] | Write-BootsOutput
    $ShowUI.ActiveWindow.Close()
}


    
    
       
       
      TextBlock -Margin 5 -Grid-Row 0 {
         "Type or click to search. Press Enter or click OK to pass the items down the pipeline." 
      }
           
      ## Store the items that came from the pipeline
      $items = New-Object "System.Windows.Data.ListCollectionView" @(,$OrderedItems)

      ScrollViewer -Margin 5 -Grid-Row 1 {
         ListBox -SelectionMode Multiple -Name SelectedItems `
                 -FontFamily "Consolas, Courier New" -ItemsSource $items `
                 -On_MouseDoubleClick { param($source,$e)
                                        $GLOBAL:originalItems[$e.OriginalSource.DataContext] | Write-UIOutput
                                        $ShowUI.ActiveWindow.Close()
                                      } | Tee -Variable global:SelectedItems

      } 

      TextBox -Margin 5 -Name SearchText -Grid-Row 2 -On_KeyUp {
         $filterText = $this.Text
         [System.Windows.Data.CollectionViewSource]::GetDefaultView( $global:SelectedItems.ItemsSource ).Filter = 
         [Predicate[Object]]{ param([string]$item)
            try
            {
               ## If this is a regex, do a regex match
               $item -match $filterText
            }
            catch
            {
               ## If the regex threw, do simple text match
               $item -like ("*" + [System.Management.Automation.WildcardPattern]::Escape($filterText) + "*")
            }
         
         }
      
      }

      GridPanel -Margin 5 -HorizontalAlignment Right -ColumnDefinitions @(
         ColumnDefinition -Width 65
         ColumnDefinition -Width 10
         ColumnDefinition -Width 65
      ) {
         Button "OK" -IsDefault -Width 65 -On_Click OK_Click -"Grid.Column" 0
         Button "Cancel" -IsCancel -Width 65 -"Grid.Column" 2
      } -"Grid.Row" 3 -Passthru
   } -On_Loaded { (Select-UIElement $this SearchText).Focus() }
} -Args $input -Export
Remove-UIWindow "Object Filter"